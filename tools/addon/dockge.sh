#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | Addon: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dockge.kuma.pet/ | Github: https://github.com/louislam/dockge
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "dockge" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Dockge"
APP_TYPE="addon"
INSTALL_PATH="/opt/dockge"
STACKS_PATH="/opt/stacks"
COMPOSE_FILE="${INSTALL_PATH}/compose.yaml"
DEFAULT_PORT=5001

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"

  if [[ -f "$COMPOSE_FILE" ]]; then
    msg_info "Stopping and removing Docker containers"
    cd "$INSTALL_PATH"
    $STD docker compose down --remove-orphans
    msg_ok "Stopped and removed Docker containers"
  fi

  rm -rf "$INSTALL_PATH"
  msg_ok "${APP} has been uninstalled"
  msg_warn "Stacks directory ${STACKS_PATH} was NOT removed. Delete manually if no longer needed."
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  msg_info "Pulling latest ${APP} image"
  cd "$INSTALL_PATH"
  $STD docker compose pull
  msg_ok "Pulled latest image"

  msg_info "Restarting ${APP}"
  $STD docker compose up -d --remove-orphans
  msg_ok "Restarted ${APP}"

  msg_ok "Updated successfully"
  exit
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  ensure_docker

  msg_info "Creating install directories"
  mkdir -p "$INSTALL_PATH" "$STACKS_PATH"
  msg_ok "Created ${INSTALL_PATH} and ${STACKS_PATH}"

  msg_info "Downloading Docker Compose file"
  curl -fsSL "https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml" -o "$COMPOSE_FILE"
  msg_ok "Downloaded Docker Compose file"

  msg_info "Starting ${APP}"
  cd "$INSTALL_PATH"
  $STD docker compose up -d
  msg_ok "Started ${APP}"

  echo ""
  msg_ok "${APP} is reachable at: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  header_info
  if [[ -f "$COMPOSE_FILE" ]]; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

header_info
confirm_not_pve_host
get_lxc_ip

# Check if already installed
if [[ -f "$COMPOSE_FILE" ]]; then
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
echo -e "${TAB}  - Dockge (via Docker Compose)"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
