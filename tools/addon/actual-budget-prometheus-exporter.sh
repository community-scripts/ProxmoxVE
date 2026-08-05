#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sakowicz/actual-budget-prometheus-exporter

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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "actual-budget-prometheus-exporter" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions
require_debian_like

# ==============================================================================
# CONFIGURATION
# ==============================================================================
VERBOSE=${var_verbose:-no}
APP="actual-budget-prometheus-exporter"
APP_TYPE="tools"
INSTALL_PATH="/opt/actual-budget-prometheus-exporter"
CONFIG_PATH="/opt/actual-budget-prometheus-exporter.env"
SERVICE_PATH="/etc/systemd/system/actual-budget-prometheus-exporter.service"

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling Actual-Budget-Prometheus-Exporter"
  systemctl disable -q --now actual-budget-prometheus-exporter
  rm -f "$SERVICE_PATH"
  rm -rf "$INSTALL_PATH"
  rm -f "$CONFIG_PATH"
  rm -f "/usr/local/bin/update_actual-budget-prometheus-exporter"
  rm -f "$HOME/.actual-budget-prometheus-exporter"
  msg_ok "Actual-Budget-Prometheus-Exporter has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "actual-budget-prometheus-exporter" "sakowicz/actual-budget-prometheus-exporter"; then
    msg_info "Stopping service"
    systemctl stop actual-budget-prometheus-exporter
    msg_ok "Stopped service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "actual-budget-prometheus-exporter" "sakowicz/actual-budget-prometheus-exporter" "tarball" "latest"
    NODE_VERSION="22" setup_nodejs

    msg_info "Building Actual-Budget-Prometheus-Exporter"
    cd "$INSTALL_PATH"
    $STD npm ci
    $STD npm run build
    msg_ok "Built Actual-Budget-Prometheus-Exporter"

    msg_info "Starting service"
    systemctl start actual-budget-prometheus-exporter
    msg_ok "Started service"
    msg_ok "Updated successfully!"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  read -erp "Enter URL of Actual Budget server, example: (http://127.0.0.1:5006): " ACTUAL_SERVER_URL
  read -rsp "Enter Actual Budget server password: " ACTUAL_PASSWORD
  printf "\n"
  echo -e "${TAB}${INFO} Find the Sync ID in Actual under Settings > Advanced settings > Sync ID"
  read -erp "Enter Budget Sync ID: " ACTUAL_BUDGET_ID_1
  read -rsp "Enter E2E encryption password (leave empty if end-to-end encryption is disabled): " ACTUAL_E2E_PASSWORD_1
  printf "\n"
  read -erp "Enter metrics port (default: 3001): " PORT_INPUT
  PORT="${PORT_INPUT:-3001}"

  # build-essential and python3 are required to compile better-sqlite3
  # (native dependency of @actual-app/api) when no prebuilt binary is available.
  msg_info "Installing Dependencies"
  $STD apt install -y build-essential python3
  msg_ok "Installed Dependencies"

  fetch_and_deploy_gh_release "actual-budget-prometheus-exporter" "sakowicz/actual-budget-prometheus-exporter" "tarball" "latest"
  NODE_VERSION="22" setup_nodejs

  msg_info "Building Actual-Budget-Prometheus-Exporter"
  cd "$INSTALL_PATH"
  $STD npm ci
  $STD npm run build
  msg_ok "Built Actual-Budget-Prometheus-Exporter"

  msg_info "Creating configuration"
  cat <<EOF >"$CONFIG_PATH"
# https://github.com/sakowicz/actual-budget-prometheus-exporter
ACTUAL_SERVER_URL="${ACTUAL_SERVER_URL}"
ACTUAL_PASSWORD="${ACTUAL_PASSWORD}"
ACTUAL_BUDGET_ID_1="${ACTUAL_BUDGET_ID_1}"
ACTUAL_E2E_PASSWORD_1="${ACTUAL_E2E_PASSWORD_1}"
PORT="${PORT}"
# Optional: friendly label for the budget shown in the exported metrics
# ACTUAL_BUDGET_NAME_1=""
# Optional: monitor additional budgets by incrementing the numeric suffix
# ACTUAL_BUDGET_ID_2=""
# ACTUAL_E2E_PASSWORD_2=""
# ACTUAL_BUDGET_NAME_2=""
# Optional: set to 0 to accept a self-signed TLS certificate on the Actual server
# NODE_TLS_REJECT_UNAUTHORIZED="0"
EOF
  msg_ok "Created configuration"

  msg_info "Creating service"
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Actual Budget Prometheus Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
WorkingDirectory=$INSTALL_PATH
EnvironmentFile=$CONFIG_PATH
ExecStart=/usr/bin/node $INSTALL_PATH/dist/app.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now actual-budget-prometheus-exporter
  msg_ok "Created and started service"

  # Create update script
  msg_info "Creating update script"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_actual-budget-prometheus-exporter
#!/usr/bin/env bash
# actual-budget-prometheus-exporter Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/actual-budget-prometheus-exporter.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_actual-budget-prometheus-exporter
  msg_ok "Created update script (/usr/local/bin/update_actual-budget-prometheus-exporter)"

  echo ""
  msg_ok "Actual-Budget-Prometheus-Exporter installed successfully"
  msg_ok "Metrics: ${BL}http://${LOCAL_IP}:${PORT}/metrics${CL}"
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
  if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/dist/app.js" ]]; then
    update
  else
    msg_error "Actual-Budget-Prometheus-Exporter is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/dist/app.js" ]]; then
  msg_warn "Actual-Budget-Prometheus-Exporter is already installed."
  echo ""

  echo -n "${TAB}Uninstall Actual-Budget-Prometheus-Exporter? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}Update Actual-Budget-Prometheus-Exporter? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "Actual-Budget-Prometheus-Exporter is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - Actual Budget Prometheus Exporter (Node.js source build)"
echo -e "${TAB}  - Systemd service"
echo ""

echo -n "${TAB}Install Actual-Budget-Prometheus-Exporter? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
