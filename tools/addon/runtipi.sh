#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://runtipi.io/ | Github: https://github.com/runtipi/runtipi
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

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Runtipi"
APP_TYPE="addon"
INSTALL_PATH="/opt/runtipi"
DEFAULT_PORT=80

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

# ==============================================================================
# PROXMOX HOST CHECK
# ==============================================================================
function check_proxmox_host() {
  if command -v pveversion &>/dev/null; then
    msg_error "Running on the Proxmox host is NOT recommended!"
    msg_error "This should be executed inside an LXC container."
    echo ""
    echo -n "${TAB}Continue anyway? (y/N): "
    read -r confirm
    if [[ ! "${confirm,,}" =~ ^(y|yes)$ ]]; then
      msg_warn "Aborted. Please run this inside an LXC container."
      exit 0
    fi
    msg_warn "Proceeding on Proxmox host at your own risk!"
  fi
}

# ==============================================================================
# CHECK / INSTALL DOCKER
# ==============================================================================
function check_or_install_docker() {
  if command -v docker &>/dev/null; then
    msg_ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') is available"
    if docker compose version &>/dev/null; then
      msg_ok "Docker Compose is available"
    else
      msg_error "Docker Compose plugin is not available. Please install it."
      exit 1
    fi
    return
  fi

  msg_warn "Docker is not installed."
  echo -n "${TAB}Install Docker now? (y/N): "
  read -r install_docker_prompt
  if [[ ! "${install_docker_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_error "Docker is required for ${APP}. Exiting."
    exit 1
  fi

  msg_info "Installing Docker"
  DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
  mkdir -p "$(dirname "$DOCKER_CONFIG_PATH")"
  echo -e '{\n  "log-driver": "journald"\n}' >"$DOCKER_CONFIG_PATH"
  $STD sh <(curl -fsSL https://get.docker.com)
  msg_ok "Installed Docker"
}

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"

  if [[ -f "${INSTALL_PATH}/runtipi-cli" ]]; then
    msg_info "Stopping ${APP}"
    cd "$INSTALL_PATH"
    $STD ./runtipi-cli stop 2>/dev/null || true
    msg_ok "Stopped ${APP}"
  fi

  if command -v docker &>/dev/null; then
    msg_info "Removing Docker containers"
    cd "$INSTALL_PATH" 2>/dev/null && $STD docker compose down --remove-orphans 2>/dev/null || true
    msg_ok "Removed Docker containers"
  fi

  rm -rf "$INSTALL_PATH"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  msg_info "Updating ${APP}"
  cd "$INSTALL_PATH"
  $STD ./runtipi-cli update latest
  msg_ok "Updated ${APP}"

  msg_ok "Updated successfully"
  exit
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  check_or_install_docker

  msg_info "Installing dependencies"
  $STD apt-get update
  $STD apt-get install -y openssl
  msg_ok "Installed dependencies"

  msg_warn "WARNING: This will run an external installer from https://runtipi.io/"
  msg_warn "The following code is NOT maintained or audited by our repository."
  msg_warn "Review: https://raw.githubusercontent.com/runtipi/runtipi/master/scripts/install.sh"
  echo ""
  echo -n "${TAB}Do you want to continue? (y/N): "
  read -r confirm
  if [[ ! "${confirm,,}" =~ ^(y|yes)$ ]]; then
    msg_warn "Installation cancelled. Exiting."
    exit 0
  fi

  msg_info "Installing ${APP} (this pulls Docker containers)"
  DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
  mkdir -p "$(dirname "$DOCKER_CONFIG_PATH")"
  [[ ! -f "$DOCKER_CONFIG_PATH" ]] && echo -e '{\n  "log-driver": "journald"\n}' >"$DOCKER_CONFIG_PATH"
  cd /opt
  curl -fsSL "https://raw.githubusercontent.com/runtipi/runtipi/master/scripts/install.sh" -o "install.sh"
  chmod +x install.sh
  $STD ./install.sh
  chmod 666 /opt/runtipi/state/settings.json 2>/dev/null || true
  rm -f /opt/install.sh
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

if [[ -f /etc/alpine-release ]]; then
  msg_error "${APP} does not support Alpine Linux. Please use a Debian or Ubuntu based LXC."
  exit 1
fi

header_info
check_proxmox_host
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
echo -e "${TAB}  - Runtipi (via external installer)"
echo -e "${TAB}  - Docker (if not already installed)"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
