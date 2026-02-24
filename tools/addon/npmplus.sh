#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ZoeyVid/NPMplus
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
APP="NPMplus"
APP_TYPE="addon"
INSTALL_PATH="/opt/npmplus"
COMPOSE_FILE="${INSTALL_PATH}/compose.yaml"
DEFAULT_PORT=81

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

# ==============================================================================
# HEADER
# ==============================================================================
function header_info {
  clear
  cat <<"EOF"
    _   ______  __  ___       __
   / | / / __ \/  |/  /____  / /_  _______
  /  |/ / /_/ / /|_/ / __ \/ / / / / ___/
 / /|  / ____/ /  / / /_/ / / /_/ (__  )
/_/ |_/_/   /_/  /_/ .___/_/\__,_/____/
                  /_/

EOF
}

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"

  if [[ -f "$COMPOSE_FILE" ]]; then
    msg_info "Stopping and removing Docker containers"
    cd "$INSTALL_PATH"
    $STD docker compose down --volumes --remove-orphans
    msg_ok "Stopped and removed Docker containers"
  fi

  rm -rf "$INSTALL_PATH"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  msg_info "Pulling latest ${APP} image"
  cd "$INSTALL_PATH"
  $STD docker compose pull
  msg_ok "Pulled latest image"

  msg_info "Recreating container"
  $STD docker compose up -d --remove-orphans
  msg_ok "Recreated container"

  msg_ok "Updated successfully"
  exit
}

# ==============================================================================
# CHECK DOCKER
# ==============================================================================
function check_docker() {
  if ! command -v docker &>/dev/null; then
    msg_error "Docker is not installed. This addon requires an existing Docker LXC. Exiting."
    exit 1
  fi
  if ! docker compose version &>/dev/null; then
    msg_error "Docker Compose plugin is not available. Please install it before running this script. Exiting."
    exit 1
  fi
  msg_ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') and Docker Compose are available"
}

# ==============================================================================
# HELPERS
# ==============================================================================
function validate_tz() {
  local tz="$1"
  [[ -f "/usr/share/zoneinfo/$tz" ]]
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  check_docker

  msg_info "Creating install directory"
  mkdir -p "$INSTALL_PATH"
  msg_ok "Created ${INSTALL_PATH}"

  # Install yq if not available
  if ! command -v yq &>/dev/null; then
    msg_info "Installing yq"
    if command -v apt-get &>/dev/null; then
      $STD apt-get install -y gawk
      YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
    elif command -v apk &>/dev/null; then
      $STD apk add --no-cache gawk yq
    fi
    if ! command -v yq &>/dev/null && [[ -n "${YQ_URL:-}" ]]; then
      curl -fsSL "$YQ_URL" -o /usr/local/bin/yq
      chmod +x /usr/local/bin/yq
    fi
    msg_ok "Installed yq"
  fi

  msg_info "Downloading Docker Compose file"
  curl -fsSL "https://raw.githubusercontent.com/ZoeyVid/NPMplus/refs/heads/develop/compose.yaml" -o "$COMPOSE_FILE"
  msg_ok "Downloaded Docker Compose file"

  # Timezone configuration
  local attempts=0
  while true; do
    echo -n "${TAB}Enter your TZ Identifier (e.g., Europe/Berlin): "
    read -r TZ_INPUT
    if validate_tz "$TZ_INPUT"; then
      break
    fi
    msg_error "Invalid timezone! Please enter a valid TZ identifier."
    attempts=$((attempts + 1))
    if [[ "$attempts" -ge 3 ]]; then
      msg_error "Maximum attempts reached. Exiting."
      exit 1
    fi
  done

  echo -n "${TAB}Enter your ACME Email: "
  read -r ACME_EMAIL_INPUT

  msg_info "Configuring NPMplus"
  yq -i "
    .services.npmplus.environment |=
      (map(select(. != \"TZ=*\" and . != \"ACME_EMAIL=*\" and . != \"INITIAL_ADMIN_EMAIL=*\" and . != \"INITIAL_ADMIN_PASSWORD=*\")) +
      [\"TZ=$TZ_INPUT\", \"ACME_EMAIL=$ACME_EMAIL_INPUT\", \"INITIAL_ADMIN_EMAIL=admin@local.com\", \"INITIAL_ADMIN_PASSWORD=helper-scripts.com\"])
  " "$COMPOSE_FILE"
  msg_ok "Configured NPMplus"

  msg_info "Starting ${APP} (pulling images, please wait)"
  cd "$INSTALL_PATH"
  $STD docker compose up -d

  # Wait for healthy container
  local CONTAINER_ID=""
  for i in {1..60}; do
    CONTAINER_ID=$(docker ps --filter "name=npmplus" --format "{{.ID}}" 2>/dev/null || echo "")
    if [[ -n "$CONTAINER_ID" ]]; then
      local STATUS
      STATUS=$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_ID" 2>/dev/null || echo "starting")
      if [[ "$STATUS" == "healthy" ]]; then
        msg_ok "${APP} is running and healthy"
        break
      elif [[ "$STATUS" == "unhealthy" ]]; then
        msg_error "${APP} container is unhealthy! Check: docker logs $CONTAINER_ID"
        exit 1
      fi
    fi
    sleep 2
    if [[ $i -eq 60 ]]; then
      msg_error "${APP} container did not become healthy within 120s."
      exit 1
    fi
  done
  msg_ok "Started ${APP}"

  echo ""
  msg_ok "${APP} is reachable at: ${BL}https://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  echo ""
  echo -e "  NPMplus Credentials"
  echo -e "  ==================="
  echo -e "  Email   : admin@local.com"
  echo -e "  Password: helper-scripts.com"
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
    exit 1
  fi
  exit 0
fi

header_info
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
echo -e "${TAB}  - NPMplus (via Docker Compose)"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
