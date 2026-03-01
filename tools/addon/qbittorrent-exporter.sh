#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/martabal/qbittorrent-exporter

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
APP="qbittorrent-exporter"
APP_TYPE="tools"
INSTALL_PATH="/opt/qbittorrent-exporter"
CONFIG_PATH="/opt/qbittorrent-exporter.env"

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  SERVICE_PATH="/etc/init.d/qbittorrent-exporter"
elif grep -qE 'ID=debian|ID=ubuntu' /etc/os-release; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/qbittorrent-exporter.service"
else
  echo -e "${CROSS} Unsupported OS detected. Exiting."
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling qBittorrent-Exporter"
  if [[ "$OS" == "Alpine" ]]; then
    rc-service qbittorrent-exporter stop &>/dev/null
    rc-update del qbittorrent-exporter &>/dev/null
    rm -f "$SERVICE_PATH"
  else
    systemctl disable -q --now qbittorrent-exporter
    rm -f "$SERVICE_PATH"
  fi
  rm -rf "$INSTALL_PATH" "$CONFIG_PATH"
  rm -f "/usr/local/bin/update_qbittorrent-exporter"
  rm -f "$HOME/.qbittorrent-exporter"
  msg_ok "qBittorrent-Exporter has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "qbittorrent-exporter" "martabal/qbittorrent-exporter"; then
    msg_info "Stopping service"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service qbittorrent-exporter stop &>/dev/null
    else
      systemctl stop qbittorrent-exporter
    fi
    msg_ok "Stopped service"

    fetch_and_deploy_gh_release "qbittorrent-exporter" "martabal/qbittorrent-exporter" "tarball" "latest"
    setup_go

    msg_info "Building qBittorrent-Exporter"
    cd /opt/qbittorrent-exporter
    $STD /usr/local/bin/go build -o ./qbittorrent-exporter
    msg_ok "Built qBittorrent-Exporter"

    msg_info "Starting service"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service qbittorrent-exporter start &>/dev/null
    else
      systemctl start qbittorrent-exporter
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
  read -erp "Enter URL of qBittorrent, example: (http://127.0.0.1:8080): " QBITTORRENT_BASE_URL
  read -erp "Enter qBittorrent username: " QBITTORRENT_USERNAME
  read -rsp "Enter qBittorrent password: " QBITTORRENT_PASSWORD
  printf "\n"

  fetch_and_deploy_gh_release "qbittorrent-exporter" "martabal/qbittorrent-exporter" "tarball" "latest"
  setup_go
  msg_info "Building qBittorrent-Exporter on ${OS}"
  cd /opt/qbittorrent-exporter
  $STD /usr/local/bin/go build -o ./qbittorrent-exporter
  msg_ok "Built qBittorrent-Exporter"

  msg_info "Creating configuration"
  cat <<EOF >"$CONFIG_PATH"
# https://github.com/martabal/qbittorrent-exporter?tab=readme-ov-file#parameters
QBITTORRENT_BASE_URL="${QBITTORRENT_BASE_URL}"
QBITTORRENT_USERNAME="${QBITTORRENT_USERNAME}"
QBITTORRENT_PASSWORD="${QBITTORRENT_PASSWORD}"
EOF
  msg_ok "Created configuration"

  msg_info "Creating service"
  if [[ "$OS" == "Debian" ]]; then
    cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=qbittorrent-exporter
After=network.target

[Service]
User=root
WorkingDirectory=/opt/qbittorrent-exporter
EnvironmentFile=$CONFIG_PATH
ExecStart=/opt/qbittorrent-exporter/qbittorrent-exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable -q --now qbittorrent-exporter
  else
    cat <<EOF >"$SERVICE_PATH"
#!/sbin/openrc-run

name="qbittorrent-exporter"
description="qBittorrent Exporter for Prometheus"
command="${INSTALL_PATH}/qbittorrent-exporter"
command_background=true
directory="/opt/qbittorrent-exporter"
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="/var/log/qbittorrent-exporter.log"
error_log="/var/log/qbittorrent-exporter.log"

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
    $STD rc-update add qbittorrent-exporter default
    $STD rc-service qbittorrent-exporter start
  fi
  msg_ok "Created and started service"

  # Create update script
  msg_info "Creating update script"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_qbittorrent-exporter
#!/usr/bin/env bash
# qbittorrent-exporter Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/qbittorrent-exporter.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_qbittorrent-exporter
  msg_ok "Created update script (/usr/local/bin/update_qbittorrent-exporter)"

  echo ""
  msg_ok "qBittorrent-Exporter installed successfully"
  msg_ok "Metrics: ${BL}http://${LOCAL_IP}:8090/metrics${CL}"
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
  if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/qbittorrent-exporter" ]]; then
    update
  else
    msg_error "qBittorrent-Exporter is not installed. Nothing to update."
    exit 1
  fi
  exit 0
fi

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/qbittorrent-exporter" ]]; then
  msg_warn "qBittorrent-Exporter is already installed."
  echo ""

  echo -n "${TAB}Uninstall qBittorrent-Exporter? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}Update qBittorrent-Exporter? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "qBittorrent-Exporter is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - qBittorrent Exporter (Go binary)"
echo -e "${TAB}  - Systemd/OpenRC service"
echo ""

echo -n "${TAB}Install qBittorrent-Exporter? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
