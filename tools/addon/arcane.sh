#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: summoningpixels
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/getarcaneapp/arcane
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "arcane" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Arcane"
APP_TYPE="addon"
INSTALL_PATH="/opt/arcane"
COMPOSE_FILE="${INSTALL_PATH}/compose.yaml"
ENV_FILE="${INSTALL_PATH}/.env"
DEFAULT_PORT=3552

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
    $STD docker compose down --volumes --remove-orphans
    msg_ok "Stopped and removed Docker containers"
  fi

  rm -rf "$INSTALL_PATH"
  rm -f "/usr/local/bin/update_arcane"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  chown -R 65532:65532 /etc/arcane/projects /etc/arcane/builds 2>/dev/null || true

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

  msg_info "Creating install directory"
  mkdir -p "$INSTALL_PATH"
  msg_ok "Created ${INSTALL_PATH}"

  # Generate secrets and config values
  local ENCRYPTION_KEY JWT_SECRET PROJ_DIR BUILDS_DIR
  ENCRYPTION_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c32)
  JWT_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c32)
  PROJ_DIR="/etc/arcane/projects"
  BUILDS_DIR="/etc/arcane/builds"

  # Arcane drops root and runs as UID/GID 65532 by default (Dockerfile default,
  # see backend/pkg/libarcane/startup/runtime_identity.go), so bind-mounted
  # host directories must be owned by that UID or the container can't write to them.
  msg_info "Creating stacks directory"
  mkdir -p "$PROJ_DIR"
  chown -R 65532:65532 "$PROJ_DIR"
  msg_ok "Created ${PROJ_DIR}"

  msg_info "Creating builds directory"
  mkdir -p "$BUILDS_DIR"
  chown -R 65532:65532 "$BUILDS_DIR"
  msg_ok "Created ${BUILDS_DIR}"

  msg_info "Downloading Docker Compose file"
  curl -fsSL "https://raw.githubusercontent.com/getarcaneapp/arcane/refs/heads/main/docker/examples/compose.basic.yaml" -o "$COMPOSE_FILE"
  msg_ok "Downloaded Docker Compose file"

  msg_info "Downloading .env file"
  curl -fsSL "https://raw.githubusercontent.com/getarcaneapp/arcane/refs/heads/main/.env.example" -o "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  msg_ok "Downloaded .env file"

  msg_info "Configuring compose and env files"
  sed -i '/^[[:space:]]*#/!s|/host/path/to/projects|'"$PROJ_DIR"'|g' "$COMPOSE_FILE"
  sed -i '/^[[:space:]]*#/!s|/host/path/to/builds|'"$BUILDS_DIR"'|g' "$COMPOSE_FILE"
  sed -i '/^[[:space:]]*#/!s|ENCRYPTION_KEY=.*|ENCRYPTION_KEY='"$ENCRYPTION_KEY"'|g' "$COMPOSE_FILE"
  sed -i '/^[[:space:]]*#/!s|JWT_SECRET=.*|JWT_SECRET='"$JWT_SECRET"'|g' "$COMPOSE_FILE"
  sed -i '/^[[:space:]]*#/!s|APP_URL=.*|APP_URL=http://localhost:'"$DEFAULT_PORT"'|g' "$ENV_FILE"
  sed -i '/^[[:space:]]*#/!s|ENCRYPTION_KEY=.*|#&|g' "$ENV_FILE"
  sed -i '/^[[:space:]]*#/!s|JWT_SECRET=.*|#&|g' "$ENV_FILE"
  msg_ok "Configured compose and env files"

  msg_info "Starting ${APP}"
  cd "$INSTALL_PATH"
  $STD docker compose up -d
  msg_ok "Started ${APP}"

  # Create update script
  msg_info "Creating update script"
  cat <<'UPDATEEOF' >/usr/local/bin/update_arcane
#!/usr/bin/env bash
# Arcane Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/arcane.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_arcane
  msg_ok "Created update script (/usr/local/bin/update_arcane)"

  echo ""
  msg_ok "${APP} is reachable at: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  echo ""
  echo -e "Arcane Credentials"
  echo -e "=================="
  echo -e "User: arcane"
  echo -e "Password: arcane-admin"
  echo ""
  msg_warn "On first access, you'll be prompted to change your password."
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
echo -e "${TAB}  - Arcane (via Docker Compose)"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
