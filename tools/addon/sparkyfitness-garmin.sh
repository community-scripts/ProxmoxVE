#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tom Frenzel (tomfrenzel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CodeWithCJ/SparkyFitness

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "sparkyfitness-garmin" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="SparkyFitness-Garmin"
APP_TYPE="addon"
INSTALL_PATH="/opt/sparkyfitness-garmin"
CONFIG_PATH="/etc/sparkyfitness-garmin/.env"
SERVICE_PATH="/etc/systemd/system/sparkyfitness-garmin.service"
DEFAULT_PORT=8000

# ==============================================================================
# OS DETECTION
# ==============================================================================
if ! grep -qE 'ID=debian|ID=ubuntu' /etc/os-release 2>/dev/null; then
  echo -e "${CROSS} Unsupported OS detected. This script only supports Debian and Ubuntu."
  exit 238
fi

# ==============================================================================
# SparkyFitness LXC DETECTION
# ==============================================================================
if [[ ! -d /opt/sparkyfitness ]]; then
  echo -e "${CROSS} No SparkyFitness installation detected. This addon must be installed within a container that already has SparkyFitness installed."
  exit 238
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"
  systemctl disable --now sparkyfitness-garmin.service &>/dev/null || true
  rm -rf "$SERVICE_PATH" "$CONFIG_PATH" "$INSTALL_PATH" ~/.sparkyfitness-garmin
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "sparkyfitness-garmin" "CodeWithCJ/SparkyFitness"; then
    PYTHON_VERSION="3.13" setup_uv

    msg_info "Stopping service"
    systemctl stop sparkyfitness-garmin.service &>/dev/null || true
    msg_ok "Stopped service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "sparkyfitness-garmin" "CodeWithCJ/SparkyFitness" "tarball" "latest" $INSTALL_PATH
    cd $INSTALL_PATH/SparkyFitnessGarmin
    $STD uv venv --clear .venv
    $STD uv pip install -r requirements.txt

    msg_info "Starting service"
    systemctl start sparkyfitness-garmin
    msg_ok "Started service"
    msg_ok "Updated successfully"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  PYTHON_VERSION="3.13" setup_uv
  fetch_and_deploy_gh_release "sparkyfitness-garmin" "CodeWithCJ/SparkyFitness" "tarball" "latest" $INSTALL_PATH

  msg_info "Setting up ${APP}"
  mkdir -p "/etc/sparkyfitness-garmin"
  cp "/opt/sparkyfitness-garmin/docker/.env.example" $CONFIG_PATH
  cd $INSTALL_PATH/SparkyFitnessGarmin
  $STD uv venv --clear .venv
  $STD uv pip install -r requirements.txt
  sed -i -e "s|^#\?GARMIN_MICROSERVICE_URL=.*|GARMIN_MICROSERVICE_URL=http://${LOCAL_IP}:${DEFAULT_PORT}|" $CONFIG_PATH
  cat <<EOF >/etc/systemd/system/sparkyfitness-garmin.service
[Unit]
Description=${APP}
After=network.target sparkyfitness-server.service
Requires=sparkyfitness-server.service

[Service]
Type=simple
WorkingDirectory=$INSTALL_PATH/SparkyFitnessGarmin
EnvironmentFile=$CONFIG_PATH
ExecStart=$INSTALL_PATH/SparkyFitnessGarmin/.venv/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port ${DEFAULT_PORT}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now sparkyfitness-garmin
  msg_ok "Set up ${APP} - reachable at http://${LOCAL_IP}:${DEFAULT_PORT}"
  msg_ok "You might need to update the GARMIN_MICROSERVICE_URL in your SparkyFitness .env file to http://${LOCAL_IP}:${DEFAULT_PORT}"
}

# ==============================================================================
# MAIN
# ==============================================================================
header_info
ensure_usr_local_bin_persist
get_lxc_ip

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  if [[ -d "$INSTALL_PATH" ]]; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

# Check if already installed
if [[ -d "$INSTALL_PATH" && -n "$(ls -A "$INSTALL_PATH" 2>/dev/null)" ]]; then
  msg_warn "${APP} is already installed."
  echo ""

  echo -n "${TAB}Uninstall ${APP}? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}Update ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "${APP} is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - UV (Python Version Manager)"
echo -e "${TAB}  - SparkyFitness Garmin Microservice"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
