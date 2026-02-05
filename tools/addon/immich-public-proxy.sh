#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alangrainger/immich-public-proxy

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)

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
DEFAULT_PORT=3000

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

# ==============================================================================
# HEADER
# ==============================================================================
function header_info {
  clear
  cat <<"EOF"
    ____                    _      __          ____
   /  _/___ ___  ____ ___  (_)____/ /_        / __ \_________  _  ____  __
   / // __ `__ \/ __ `__ \/ / ___/ __ \______/ /_/ / ___/ __ \| |/_/ / / /
 _/ // / / / / / / / / / / / /__/ / / /_____/ ____/ /  / /_/ />  </ /_/ /
/___/_/ /_/ /_/_/ /_/ /_/_/\___/_/ /_/     /_/   /_/   \____/_/|_|\__, /
                                                                 /____/
EOF
}

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  msg_error "Alpine is not supported for ${APP}. Use Debian."
  exit 1
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/immich-proxy.service"
else
  echo -e "${CROSS} Unsupported OS detected. Exiting."
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling ${APP}"
  systemctl disable --now immich-proxy.service &>/dev/null || true
  rm -f "$SERVICE_PATH"
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
    systemctl stop immich-proxy.service &>/dev/null || true
    msg_ok "Stopped service"

    msg_info "Backing up configuration"
    cp "$CONFIG_PATH"/.env /tmp/ipp.env.bak 2>/dev/null || true
    cp "$CONFIG_PATH"/config.json /tmp/ipp.config.json.bak 2>/dev/null || true
    msg_ok "Backed up configuration"

    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Immich Public Proxy" "alangrainger/immich-public-proxy" "tarball" "latest" "$INSTALL_PATH"

    msg_info "Restoring configuration"
    cp /tmp/ipp.env.bak "$CONFIG_PATH"/.env 2>/dev/null || true
    cp /tmp/ipp.config.json.bak "$CONFIG_PATH"/config.json 2>/dev/null || true
    rm -f /tmp/ipp.*.bak
    msg_ok "Restored configuration"

    msg_info "Installing dependencies"
    cd "$CONFIG_PATH"
    $STD npm install
    msg_ok "Installed dependencies"

    msg_info "Building ${APP}"
    $STD npm run build
    msg_ok "Built ${APP}"

    msg_info "Starting service"
    systemctl start immich-proxy
    msg_ok "Started service"
    msg_ok "Updated successfully"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  NODE_VERSION="24" setup_nodejs

  # Force fresh download by removing version cache
  rm -f "$HOME/.immichpublicproxy"
  fetch_and_deploy_gh_release "Immich Public Proxy" "alangrainger/immich-public-proxy" "tarball" "latest" "$INSTALL_PATH"

  msg_info "Installing dependencies"
  cd "$CONFIG_PATH"
  $STD npm install
  msg_ok "Installed dependencies"

  msg_info "Building ${APP}"
  $STD npm run build
  msg_ok "Built ${APP}"

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
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Immich Public Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}
EnvironmentFile=${CONFIG_PATH}/.env
ExecStart=/usr/bin/node ${INSTALL_PATH}/app/server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now immich-proxy
  msg_ok "Created and started service"

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
    exit 1
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
