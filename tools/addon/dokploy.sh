#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dokploy.com/
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

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Dokploy"
APP_TYPE="addon"
INSTALL_PATH="/etc/dokploy"
DEFAULT_PORT=3000

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

# ==============================================================================
# HEADER
# ==============================================================================
function header_info {
  clear
  cat <<"EOF"
    ____        __         __
   / __ \____  / /______  / /___  __  __
  / / / / __ \/ //_/ __ \/ / __ \/ / / /
 / /_/ / /_/ / ,< / /_/ / / /_/ / /_/ /
/_____/\____/_/|_| .___/_/\____/\__, /
                /_/            /____/

EOF
}

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"

  if command -v docker &>/dev/null; then
    msg_info "Stopping and removing Docker containers"
    $STD docker stop $(docker ps -aq) 2>/dev/null || true
    $STD docker rm $(docker ps -aq) 2>/dev/null || true
    $STD docker network prune -f 2>/dev/null || true
    msg_ok "Stopped and removed Docker containers"
  fi

  rm -rf "$INSTALL_PATH"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  msg_info "Updating ${APP}"
  $STD curl -sSL https://dokploy.com/install.sh | bash -s update
  msg_ok "Updated ${APP}"

  msg_ok "Updated successfully"
  exit
}

# ==============================================================================
# CHECK DOCKER
# ==============================================================================
function check_docker() {
  if ! command -v docker &>/dev/null; then
    msg_warn "Docker is not installed — Dokploy installer will set it up."
    return
  fi
  msg_ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') is available"
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  check_docker

  msg_info "Installing dependencies"
  $STD apt-get update
  $STD apt-get install -y git openssl redis
  msg_ok "Installed dependencies"

  msg_warn "WARNING: This will run an external installer from https://dokploy.com/"
  msg_warn "The following code is NOT maintained or audited by our repository."
  echo ""
  echo -n "${TAB}Do you want to continue? (y/N): "
  read -r confirm
  if [[ ! "${confirm,,}" =~ ^(y|yes)$ ]]; then
    msg_warn "Installation cancelled. Exiting."
    exit 0
  fi

  msg_info "Installing ${APP} (this installs Docker and pulls containers)"
  $STD bash <(curl -sSL https://dokploy.com/install.sh)
  msg_ok "Installed ${APP}"

  echo ""
  msg_ok "${APP} is reachable at: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  header_info
  if [[ -d "$INSTALL_PATH" ]]; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 1
  fi
  exit 0
fi

header_info
get_lxc_ip

# Check if already installed
if [[ -d "$INSTALL_PATH" ]]; then
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
echo -e "${TAB}  - Dokploy (via external installer)"
echo -e "${TAB}  - Docker (if not already installed)"
echo -e "${TAB}  - Redis"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
