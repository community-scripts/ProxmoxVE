#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://komo.do/ | Github: https://github.com/mbecker20/komodo
if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1 || apk update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1 || apk add --no-cache curl >/dev/null 2>&1
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
APP="Komodo"
APP_TYPE="addon"
INSTALL_PATH="/opt/komodo"
COMPOSE_ENV="${INSTALL_PATH}/compose.env"
DEFAULT_PORT=9120

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

# ==============================================================================
# HELPERS
# ==============================================================================
function find_compose_file() {
  COMPOSE_FILE=$(find "$INSTALL_PATH" -maxdepth 1 -type f -name '*.compose.yaml' ! -name 'compose.env' | head -n1)
  if [[ -z "${COMPOSE_FILE:-}" ]]; then
    msg_error "No valid compose file found in ${INSTALL_PATH}!"
    exit 233
  fi
  COMPOSE_BASENAME=$(basename "$COMPOSE_FILE")
}

function check_legacy_db() {
  if [[ "$COMPOSE_BASENAME" == "sqlite.compose.yaml" || "$COMPOSE_BASENAME" == "postgres.compose.yaml" ]]; then
    msg_error "Detected outdated Komodo setup using SQLite or PostgreSQL (FerretDB v1)."
    echo -e "${YW}This configuration is no longer supported since Komodo v1.18.0.${CL}"
    echo -e "${YW}Please follow the migration guide:${CL}"
    echo -e "${BGN}https://github.com/community-scripts/ProxmoxVE/discussions/5689${CL}\n"
    exit 238
  fi
}

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"

  find_compose_file
  msg_info "Stopping and removing Docker containers"
  cd "$INSTALL_PATH"
  $STD docker compose -p komodo -f "$COMPOSE_FILE" --env-file "$COMPOSE_ENV" down --volumes --remove-orphans
  msg_ok "Stopped and removed Docker containers"

  rm -rf "$INSTALL_PATH"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  find_compose_file
  check_legacy_db

  msg_info "Updating ${APP}"
  BACKUP_FILE="${INSTALL_PATH}/${COMPOSE_BASENAME}.bak_$(date +%Y%m%d_%H%M%S)"
  cp "$COMPOSE_FILE" "$BACKUP_FILE" || {
    msg_error "Failed to create backup of ${COMPOSE_BASENAME}!"
    exit 235
  }

  GITHUB_URL="https://raw.githubusercontent.com/moghtech/komodo/main/compose/${COMPOSE_BASENAME}"
  if ! curl -fsSL "$GITHUB_URL" -o "$COMPOSE_FILE"; then
    msg_error "Failed to download ${COMPOSE_BASENAME} from GitHub!"
    mv "$BACKUP_FILE" "$COMPOSE_FILE"
    exit 115
  fi

  if ! grep -qxF 'COMPOSE_KOMODO_BACKUPS_PATH=/etc/komodo/backups' "$COMPOSE_ENV"; then
    sed -i '/^COMPOSE_KOMODO_IMAGE_TAG=latest$/a COMPOSE_KOMODO_BACKUPS_PATH=/etc/komodo/backups' "$COMPOSE_ENV"
  fi

  $STD docker compose -p komodo -f "$COMPOSE_FILE" --env-file "$COMPOSE_ENV" pull
  $STD docker compose -p komodo -f "$COMPOSE_FILE" --env-file "$COMPOSE_ENV" up -d
  msg_ok "Updated ${APP}"

  msg_ok "Updated successfully"
  exit
}

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
      exit 10
    fi
    return
  fi

  msg_warn "Docker is not installed."
  echo -n "${TAB}Install Docker now? (y/N): "
  read -r install_docker_prompt
  if [[ ! "${install_docker_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_error "Docker is required for ${APP}. Exiting."
    exit 10
  fi

  msg_info "Installing Docker"
  if [[ -f /etc/alpine-release ]]; then
    $STD apk add docker docker-cli-compose
    $STD rc-service docker start
    $STD rc-update add docker default
  else
    DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
    mkdir -p "$(dirname "$DOCKER_CONFIG_PATH")"
    echo -e '{\n  "log-driver": "journald"\n}' >"$DOCKER_CONFIG_PATH"
    $STD sh <(curl -fsSL https://get.docker.com)
  fi
  msg_ok "Installed Docker"
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  check_or_install_docker

  echo -e "${TAB}Choose the database for Komodo:"
  echo -e "${TAB}  1) MongoDB (recommended)"
  echo -e "${TAB}  2) FerretDB"
  echo -n "${TAB}Enter your choice (default: 1): "
  read -r DB_CHOICE
  DB_CHOICE=${DB_CHOICE:-1}

  case $DB_CHOICE in
  1) DB_COMPOSE_FILE="mongo.compose.yaml" ;;
  2) DB_COMPOSE_FILE="ferretdb.compose.yaml" ;;
  *)
    msg_warn "Invalid choice. Defaulting to MongoDB."
    DB_COMPOSE_FILE="mongo.compose.yaml"
    ;;
  esac

  msg_info "Creating install directory"
  mkdir -p "$INSTALL_PATH"
  msg_ok "Created ${INSTALL_PATH}"

  msg_info "Downloading Docker Compose file"
  curl -fsSL "https://raw.githubusercontent.com/moghtech/komodo/main/compose/$DB_COMPOSE_FILE" -o "${INSTALL_PATH}/${DB_COMPOSE_FILE}"
  msg_ok "Downloaded ${DB_COMPOSE_FILE}"

  msg_info "Configuring environment"
  curl -fsSL "https://raw.githubusercontent.com/moghtech/komodo/main/compose/compose.env" -o "$COMPOSE_ENV"

  DB_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=')
  ADMIN_PASSWORD=$(openssl rand -base64 8 | tr -d '/+=')
  PASSKEY=$(openssl rand -base64 24 | tr -d '/+=')
  WEBHOOK_SECRET=$(openssl rand -base64 24 | tr -d '/+=')
  JWT_SECRET=$(openssl rand -base64 24 | tr -d '/+=')

  sed -i "s/^KOMODO_DB_USERNAME=.*/KOMODO_DB_USERNAME=komodo_admin/" "$COMPOSE_ENV"
  sed -i "s/^KOMODO_DB_PASSWORD=.*/KOMODO_DB_PASSWORD=${DB_PASSWORD}/" "$COMPOSE_ENV"
  sed -i "s/^KOMODO_INIT_ADMIN_PASSWORD=changeme/KOMODO_INIT_ADMIN_PASSWORD=${ADMIN_PASSWORD}/" "$COMPOSE_ENV"
  sed -i "s/^KOMODO_PASSKEY=.*/KOMODO_PASSKEY=${PASSKEY}/" "$COMPOSE_ENV"
  sed -i "s/^KOMODO_WEBHOOK_SECRET=.*/KOMODO_WEBHOOK_SECRET=${WEBHOOK_SECRET}/" "$COMPOSE_ENV"
  sed -i "s/^KOMODO_JWT_SECRET=.*/KOMODO_JWT_SECRET=${JWT_SECRET}/" "$COMPOSE_ENV"
  msg_ok "Configured environment"

  msg_info "Starting ${APP}"
  cd "$INSTALL_PATH"
  $STD docker compose -p komodo -f "${INSTALL_PATH}/${DB_COMPOSE_FILE}" --env-file "$COMPOSE_ENV" up -d
  msg_ok "Started ${APP}"

  {
    echo "Komodo Credentials"
    echo ""
    echo "Admin User    : admin"
    echo "Admin Password: $ADMIN_PASSWORD"
  } >>~/komodo.creds

  echo ""
  msg_ok "${APP} is reachable at: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  echo ""
  echo -e "  Komodo Credentials"
  echo -e "  =================="
  echo -e "  User    : admin"
  echo -e "  Password: ${ADMIN_PASSWORD}"
  echo ""
  msg_info "Credentials saved to ~/komodo.creds"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  header_info
  COMPOSE_FILE=""
  COMPOSE_BASENAME=""
  if [[ -d "$INSTALL_PATH" ]]; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

header_info
check_proxmox_host
get_lxc_ip

# Declare variables used by find_compose_file
COMPOSE_FILE=""
COMPOSE_BASENAME=""

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
echo -e "${TAB}  - Komodo (via Docker Compose)"
echo -e "${TAB}  - MongoDB or FerretDB (your choice)"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
