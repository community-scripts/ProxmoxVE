#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alangrainger/immich-public-proxy

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
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/lib/tools.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/error_handler.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/api/api.func") 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "immich-public-proxy" "addon"

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Immich Public Proxy"
APP_TYPE="addon"
INSTALL_PATH="/opt/immich-proxy"
CONFIG_PATH="/opt/immich-proxy/app"
SERVICE_PATH="/etc/systemd/system/immich-proxy.service"
UPLOAD_SERVICE_PATH="/etc/systemd/system/immich-proxy-upload.service"
DEFAULT_PORT=3000
UPLOAD_PORT=3001

# Initialize all core functions (colors, formatting, icons, $STD mode)
load_functions
require_debian_like

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"
  systemctl disable --now immich-proxy.service immich-proxy-upload.service &>/dev/null || true
  rm -f "$SERVICE_PATH" "$UPLOAD_SERVICE_PATH"
  rm -rf "$INSTALL_PATH"
  rm -f "/usr/local/bin/update_immich-public-proxy"
  rm -f "$HOME/.immichpublicproxy"
  msg_ok "${APP} has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "Immich Public Proxy" "alangrainger/immich-public-proxy"; then
    msg_info "Stopping service"
    systemctl stop immich-proxy.service immich-proxy-upload.service &>/dev/null || true
    msg_ok "Stopped service"

    BACKUP_DIR="/opt/immich-public-proxy_backup"
    create_backup "$CONFIG_PATH"/.env "$CONFIG_PATH"/config.json
    if [[ -f "$UPLOAD_SERVICE_PATH" ]]; then
      create_backup "$INSTALL_PATH"/upload-app/config.json
    fi

    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Immich Public Proxy" "alangrainger/immich-public-proxy" "tarball" "latest" "$INSTALL_PATH"

    restore_backup
    build_app

    msg_info "Updating service"
    create_service
    if [[ -f "$UPLOAD_SERVICE_PATH" ]]; then
      create_upload_service
    fi
    msg_ok "Updated service"

    msg_info "Starting service"
    systemctl start immich-proxy
    if [[ -f "$UPLOAD_SERVICE_PATH" ]]; then
      systemctl start immich-proxy-upload
    fi
    msg_ok "Started service"
    msg_ok "Updated successfully"
    exit
  fi
}

function create_service() {
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Immich Public Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}/app
EnvironmentFile=${CONFIG_PATH}/.env
ExecStart=/usr/bin/node ${INSTALL_PATH}/app/dist/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
}

# The workspace root builds shared, app and upload-app together
function build_app() {
  msg_info "Installing dependencies"
  cd "$INSTALL_PATH"
  $STD npm ci
  msg_ok "Installed dependencies"

  msg_info "Building ${APP}"
  $STD npm run build
  msg_ok "Built ${APP}"
}

# env sets the port after EnvironmentFile, so an IPP_PORT in .env cannot clash with IPP
function create_upload_service() {
  cat <<EOF >"$UPLOAD_SERVICE_PATH"
[Unit]
Description=Immich Public Proxy visitor uploads
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}/upload-app
EnvironmentFile=${CONFIG_PATH}/.env
ExecStart=/usr/bin/env IPP_PORT=${UPLOAD_PORT} /usr/bin/node ${INSTALL_PATH}/upload-app/dist/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
}

function enable_uploads() {
  if [[ ! -d "$INSTALL_PATH"/upload-app ]]; then
    msg_error "Visitor uploads need ${APP} 4.0 or newer. Update first."
    exit 1
  fi
  if [[ ! -f "$INSTALL_PATH"/upload-app/dist/index.js ]]; then
    build_app
  fi
  msg_info "Enabling visitor uploads"
  create_upload_service
  systemctl enable -q --now immich-proxy-upload
  msg_ok "Enabled visitor uploads on port ${UPLOAD_PORT}"
  msg_warn "Route /upload/* on your reverse proxy to http://${LOCAL_IP}:${UPLOAD_PORT} and turn on 'Allow public user to upload' for the share in Immich"
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  NODE_VERSION="24" setup_nodejs

  # Force fresh download by removing version cache
  rm -f "$HOME/.immichpublicproxy"
  fetch_and_deploy_gh_release "Immich Public Proxy" "alangrainger/immich-public-proxy" "tarball" "latest" "$INSTALL_PATH"
  build_app

  MAX_ATTEMPTS=3
  attempt=0
  while true; do
    attempt=$((attempt + 1))
    read -rp "${TAB3}Enter your LOCAL Immich IP or domain (ex. 192.168.1.100 or immich.local.lan): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
      if ((attempt >= MAX_ATTEMPTS)); then
        DOMAIN="${LOCAL_IP:-localhost}"
        msg_warn "Using fallback: $DOMAIN"
        break
      fi
      msg_warn "Domain cannot be empty! (Attempt $attempt/$MAX_ATTEMPTS)"
    elif [[ "$DOMAIN" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      valid_ip=true
      IFS='.' read -ra octets <<<"$DOMAIN"
      for octet in "${octets[@]}"; do
        if ((octet > 255)); then
          valid_ip=false
          break
        fi
      done
      if $valid_ip; then
        break
      else
        msg_warn "Invalid IP address!"
      fi
    elif [[ "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ || "$DOMAIN" == "localhost" ]]; then
      break
    else
      msg_warn "Invalid domain format!"
    fi
  done

  msg_info "Creating configuration"
  cat <<EOF >"$CONFIG_PATH"/.env
NODE_ENV=production
IMMICH_URL=http://${DOMAIN}:2283
EOF
  chmod 600 "$CONFIG_PATH"/.env
  msg_ok "Created configuration"

  msg_info "Creating service"
  create_service
  systemctl enable -q --now immich-proxy
  msg_ok "Created and started service"

  prompt="${var_ipp_uploads:-}"
  [[ -n "$prompt" ]] || read -r -p "${TAB3}Enable visitor uploads (second service on port ${UPLOAD_PORT})? <y/N> " prompt
  if [[ "${prompt,,}" =~ ^(y|yes|true)$ ]]; then
    enable_uploads
  fi

  # Create update script (simple wrapper that calls this addon with type=update)
  msg_info "Creating update script"
  cat <<'UPDATEEOF' >/usr/local/bin/update_immich-public-proxy
#!/usr/bin/env bash
# Immich Public Proxy Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/immich-public-proxy.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_immich-public-proxy
  msg_ok "Created update script (/usr/local/bin/update_immich-public-proxy)"

  echo ""
  msg_ok "${APP} is reachable at: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  echo ""
  msg_warn "Additional configuration is available at '/opt/immich-proxy/app/config.json'"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  header_info
  if [[ -d "$INSTALL_PATH" && -f "$SERVICE_PATH" ]]; then
    update
  else
    msg_error "${APP} is not installed. Nothing to update."
    exit 233
  fi
  exit 0
fi

header_info
get_lxc_ip

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$SERVICE_PATH" ]]; then
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

  if [[ ! -f "$UPLOAD_SERVICE_PATH" ]]; then
    echo -n "${TAB}Enable visitor uploads (second service on port ${UPLOAD_PORT})? (y/N): "
    read -r upload_prompt
    if [[ "${upload_prompt,,}" =~ ^(y|yes)$ ]]; then
      enable_uploads
      exit 0
    fi
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "${APP} is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - Node.js 24"
echo -e "${TAB}  - Immich Public Proxy"
echo ""

echo -n "${TAB}Install ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
