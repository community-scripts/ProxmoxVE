#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/eko/pihole-exporter/

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions
init_tool_telemetry "" "addon"

# ==============================================================================
# CONFIGURATION
# ==============================================================================
VERBOSE=${var_verbose:-no}
APP="pihole-exporter"
APP_TYPE="tools"
INSTALL_PATH="/opt/pihole-exporter"
CONFIG_PATH="/opt/pihole-exporter.env"

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  SERVICE_PATH="/etc/init.d/pihole-exporter"
elif grep -qE 'ID=debian|ID=ubuntu' /etc/os-release; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/pihole-exporter.service"
else
  echo -e "${CROSS} Unsupported OS detected. Exiting."
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling Pihole-Exporter"
  if [[ "$OS" == "Alpine" ]]; then
    rc-service pihole-exporter stop &>/dev/null
    rc-update del pihole-exporter &>/dev/null
    rm -f "$SERVICE_PATH"
  else
    systemctl disable -q --now pihole-exporter
    rm -f "$SERVICE_PATH"
  fi
  rm -rf "$INSTALL_PATH" "$CONFIG_PATH"
  rm -f "/usr/local/bin/update_pihole-exporter"
  rm -f "$HOME/.pihole-exporter"
  msg_ok "Pihole-Exporter has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "pihole-exporter" "eko/pihole-exporter"; then
    msg_info "Stopping service"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service pihole-exporter stop &>/dev/null
    else
      systemctl stop pihole-exporter
    fi
    msg_ok "Stopped service"

    fetch_and_deploy_gh_release "pihole-exporter" "eko/pihole-exporter" "tarball" "latest"
    setup_go

    msg_info "Building Pihole-Exporter"
    cd /opt/pihole-exporter/
    $STD /usr/local/bin/go build -o ./pihole-exporter
    msg_ok "Built Pihole-Exporter"

    msg_info "Starting service"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service pihole-exporter start &>/dev/null
    else
      systemctl start pihole-exporter
    fi
    msg_ok "Started service"
    msg_ok "Updated successfully!"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  read -erp "Enter the protocol to use (http/https), default https: " pihole_PROTOCOL
  read -erp "Enter the hostname of Pihole, example: (127.0.0.1): " pihole_HOSTNAME
  read -erp "Enter the port of Pihole, default 443: " pihole_PORT
  read -rsp "Enter Pihole password: " pihole_PASSWORD
  printf "\n"
  read -erp "Do you want to skip TLS-Verification (if using a self-signed Certificate on Pi-Hole) [y/N]: " SKIP_TLS
  if [[ "${SKIP_TLS,,}" =~ ^(y|yes)$ ]]; then
    pihole_SKIP_TLS="true"
  fi

  fetch_and_deploy_gh_release "pihole-exporter" "eko/pihole-exporter" "tarball" "latest"
  setup_go
  msg_info "Building Pihole-Exporter on ${OS}"
  cd /opt/pihole-exporter/
  $STD /usr/local/bin/go build -o ./pihole-exporter
  msg_ok "Built Pihole-Exporter"

  msg_info "Creating configuration"
  cat <<EOF >"$CONFIG_PATH"
# https://github.com/eko/pihole-exporter/?tab=readme-ov-file#available-cli-options
PIHOLE_PASSWORD="${pihole_PASSWORD}"
PIHOLE_HOSTNAME="${pihole_HOSTNAME:-127.0.0.1}"
PIHOLE_PORT="${pihole_PORT:-443}"
SKIP_TLS_VERIFICATION="${pihole_SKIP_TLS:-false}"
PIHOLE_PROTOCOL="${pihole_PROTOCOL:-https}"
EOF
  msg_ok "Created configuration"

  msg_info "Creating service"
  if [[ "$OS" == "Debian" ]]; then
    cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=pihole-exporter
After=network.target

[Service]
User=root
WorkingDirectory=/opt/pihole-exporter
EnvironmentFile=$CONFIG_PATH
ExecStart=/opt/pihole-exporter/pihole-exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable -q --now pihole-exporter
  else
    cat <<EOF >"$SERVICE_PATH"
#!/sbin/openrc-run

name="pihole-exporter"
description="Pi-hole Exporter for Prometheus"
command="${INSTALL_PATH}/pihole-exporter"
command_background=true
directory="/opt/pihole-exporter"
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="/var/log/pihole-exporter.log"
error_log="/var/log/pihole-exporter.log"

depend() {
    need net
    after firewall
}

start_pre() {
    if [ -f "$CONFIG_PATH" ]; then
        export \$(grep -v '^#' $CONFIG_PATH | xargs)
    fi
}
EOF
    chmod +x "$SERVICE_PATH"
    $STD rc-update add pihole-exporter default
    $STD rc-service pihole-exporter start
  fi
  msg_ok "Created and started service"

  # Create update script
  msg_info "Creating update script"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_pihole-exporter
#!/usr/bin/env bash
# pihole-exporter Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/pihole-exporter.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_pihole-exporter
  msg_ok "Created update script (/usr/local/bin/update_pihole-exporter)"

  echo ""
  msg_ok "Pihole-Exporter installed successfully"
  msg_ok "Metrics: ${BL}http://${LOCAL_IP}:9617/metrics${CL}"
  msg_ok "Config: ${BL}${CONFIG_PATH}${CL}"
}

# ==============================================================================
# MAIN
# ==============================================================================
header_info
ensure_usr_local_bin_persist
get_lxc_ip

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/pihole-exporter" ]]; then
    update
  else
    msg_error "Pihole-Exporter is not installed. Nothing to update."
    exit 1
  fi
  exit 0
fi

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/pihole-exporter" ]]; then
  msg_warn "Pihole-Exporter is already installed."
  echo ""

  echo -n "${TAB}Uninstall Pihole-Exporter? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}Update Pihole-Exporter? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "Pihole-Exporter is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - Pi-hole Exporter (Go binary)"
echo -e "${TAB}  - Systemd/OpenRC service"
echo ""

echo -n "${TAB}Install Pihole-Exporter? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
