#!/usr/bin/env bash

# community-scripts ORG | Dockhand Addon Installer
# Author: MickLesk (CanbiZ)
# License: MIT
# Source: https://github.com/Finsys/dockhand

if command -v curl >/dev/null 2>&1; then
  source <(curl -fsSL ${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func)
  load_functions
elif command -v wget >/dev/null 2>&1; then
  source <(wget -qO- ${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func)
  load_functions
fi
source <(curl -fsSL ${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/lib/tools.func)

color
catch_errors

APP="Dockhand"
APP_TYPE="addon"
INSTALL_PATH="/opt/dockhand"
COMPOSE_FILE="${INSTALL_PATH}/docker-compose.yaml"
DEFAULT_PORT=3000

header_info "$APP"

IP=$(_get_current_ip)

function check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    msg_error "Docker is not installed. This addon requires an existing Docker host/LXC. Exiting."
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    msg_error "Docker Compose plugin is not available. Install it before running this addon. Exiting."
    exit 1
  fi
  msg_ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') and Docker Compose are available"
}

function install_dockhand() {
  local port="${1:-$DEFAULT_PORT}"
  check_docker

  msg_info "Creating Compose Project"
  mkdir -p "$INSTALL_PATH"
  cat <<EOF >"$COMPOSE_FILE"
services:
  dockhand:
    image: fnsys/dockhand:latest
    container_name: dockhand
    restart: unless-stopped
    ports:
      - ${port}:3000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - dockhand_data:/app/data

volumes:
  dockhand_data:
EOF
  msg_ok "Created Compose Project"

  msg_info "Starting ${APP}"
  cd "$INSTALL_PATH"
  $STD docker compose up -d
  msg_ok "Started ${APP}"

  msg_ok "${APP} is reachable at http://${IP}:${port}"
  echo -e "${TAB}Open the URL and complete the first-run setup wizard to create the admin account."
}

function update_dockhand() {
  msg_info "Pulling latest ${APP} image"
  cd "$INSTALL_PATH"
  $STD docker compose pull
  msg_ok "Pulled latest image"

  msg_info "Restarting ${APP}"
  $STD docker compose up -d --remove-orphans
  msg_ok "Restarted ${APP}"

  msg_ok "${APP} updated successfully"
}

function uninstall_dockhand() {
  msg_info "Removing ${APP}"
  cd "$INSTALL_PATH"
  $STD docker compose down --remove-orphans
  cd /
  rm -rf "$INSTALL_PATH"
  msg_ok "${APP} uninstalled (the dockhand_data volume was kept; remove it with: docker volume rm dockhand_data)"
}

if [[ -f "$COMPOSE_FILE" ]]; then
  read -r -p "Update (1), Uninstall (2), Cancel (3)? [1/2/3]: " action
  action="${action//[[:space:]]/}"
  case "$action" in
  1) update_dockhand ;;
  2) uninstall_dockhand ;;
  3) msg_info "Cancelled" ;;
  *) msg_error "Invalid input" ;;
  esac
else
  read -r -p "Enter port number (default: ${DEFAULT_PORT}): " PORT_INPUT
  PORT="${PORT_INPUT:-$DEFAULT_PORT}"
  read -r -p "Install ${APP}? (y/n): " answer
  answer="${answer//[[:space:]]/}"
  [[ "${answer,,}" =~ ^(y|yes)$ ]] && install_dockhand "$PORT" || msg_info "Installation skipped"
fi
