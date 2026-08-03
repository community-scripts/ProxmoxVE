#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hansmi/prometheus-paperless-exporter

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  if [[ -f /etc/alpine-release ]]; then
    apk update >/dev/null 2>&1
    apk add --no-cache curl >/dev/null 2>&1
  else
    apt-get update >/dev/null 2>&1
    apt-get install -y curl >/dev/null 2>&1
  fi
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "prometheus-paperless-ngx-exporter" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions
require_debian_like

# ==============================================================================
# CONFIGURATION
# ==============================================================================
VERBOSE=${var_verbose:-no}
APP="prometheus-paperless-ngx-exporter"
APP_TYPE="tools"
BINARY_PATH="/usr/bin/prometheus-paperless-exporter"
CONFIG_PATH="/etc/prometheus-paperless-ngx-exporter/config.env"
SERVICE_PATH="/etc/systemd/system/prometheus-paperless-ngx-exporter.service"
AUTH_TOKEN_FILE="/etc/prometheus-paperless-ngx-exporter/paperless_auth_token_file"

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling Prometheus-Paperless-NGX-Exporter"
  systemctl disable -q --now prometheus-paperless-ngx-exporter

  if dpkg -l | grep -q prometheus-paperless-exporter; then
    $STD apt-get remove -y prometheus-paperless-exporter || $STD dpkg -r prometheus-paperless-exporter
  fi

  rm -f "$SERVICE_PATH"
  rm -rf /etc/prometheus-paperless-ngx-exporter
  rm -f "/usr/local/bin/update_prometheus-paperless-ngx-exporter"
  rm -f "$HOME/.prometheus-paperless-ngx-exporter"
  msg_ok "Prometheus-Paperless-NGX-Exporter has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  local release_found=1

  if check_for_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter"; then
    release_found=0
    msg_info "Stopping service"
    systemctl stop prometheus-paperless-ngx-exporter
    msg_ok "Stopped service"

    fetch_and_deploy_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter" "binary" "latest"
  fi

  msg_info "Refreshing service configuration"
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Prometheus Paperless NGX Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
EnvironmentFile=$CONFIG_PATH
ExecStart=$BINARY_PATH \\
    --paperless_url=\${PAPERLESS_URL} \\
    --paperless_auth_token_file=$AUTH_TOKEN_FILE \\
    --paperless_header 'Accept: application/json; version=9' \\
    --collectors=tag,correspondent,document_type,storage_path,task,log,group,user,status,statistics
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  msg_ok "Refreshed service configuration"

  msg_info "Starting service"
  systemctl restart prometheus-paperless-ngx-exporter
  msg_ok "Started service"

  if [[ $release_found -eq 0 ]]; then
    msg_ok "Updated successfully!"
  else
    msg_ok "No new release found, service configuration refreshed"
  fi
  exit
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  read -erp "Enter URL of Paperless-NGX, example: (http://127.0.0.1:8000): " PAPERLESS_URL
  read -rsp "Enter Paperless-NGX authentication token: " PAPERLESS_AUTH_TOKEN
  printf "\n"

  fetch_and_deploy_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter" "binary" "latest"

  msg_info "Creating configuration"
  mkdir -p /etc/prometheus-paperless-ngx-exporter
  cat <<EOF >"$CONFIG_PATH"
# https://github.com/hansmi/prometheus-paperless-exporter
PAPERLESS_URL="${PAPERLESS_URL}"
EOF
  echo "${PAPERLESS_AUTH_TOKEN}" >"$AUTH_TOKEN_FILE"
  chmod 600 "$AUTH_TOKEN_FILE"
  msg_ok "Created configuration"

  msg_info "Creating service"
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Prometheus Paperless NGX Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
EnvironmentFile=$CONFIG_PATH
ExecStart=$BINARY_PATH \\
    --paperless_url=\${PAPERLESS_URL} \\
    --paperless_auth_token_file=$AUTH_TOKEN_FILE \\
    --paperless_header 'Accept: application/json; version=9' \\
    --collectors=tag,correspondent,document_type,storage_path,task,log,group,user,status,statistics
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q --now prometheus-paperless-ngx-exporter
  msg_ok "Created and started service"

  # Create update script
  msg_info "Creating update script"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_prometheus-paperless-ngx-exporter
#!/usr/bin/env bash
# prometheus-paperless-ngx-exporter Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/prometheus-paperless-ngx-exporter.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_prometheus-paperless-ngx-exporter
  msg_ok "Created update script (/usr/local/bin/update_prometheus-paperless-ngx-exporter)"

  echo ""
  msg_ok "Prometheus-Paperless-NGX-Exporter installed successfully"
  msg_ok "Metrics: ${BL}http://${LOCAL_IP}:8081/metrics${CL}"
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
  if [[ -f "$BINARY_PATH" ]]; then
    update
  else
    msg_error "Prometheus-Paperless-NGX-Exporter is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

# Check if already installed
if [[ -f "$BINARY_PATH" ]]; then
  msg_warn "Prometheus-Paperless-NGX-Exporter is already installed."
  echo ""

  echo -n "${TAB}Uninstall Prometheus-Paperless-NGX-Exporter? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}Update Prometheus-Paperless-NGX-Exporter? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "Prometheus-Paperless-NGX-Exporter is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - Prometheus Paperless NGX Exporter (binary)"
echo -e "${TAB}  - Systemd service"
echo ""

echo -n "${TAB}Install Prometheus-Paperless-NGX-Exporter? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
