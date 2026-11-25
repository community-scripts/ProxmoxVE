#!/usr/bin/env bash

# community-scripts ORG | Immich Power Tools Addon Installer
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/immich-power-tools/immich-power-tools

if command -v curl >/dev/null 2>&1; then
  source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
  load_functions
elif command -v wget >/dev/null 2>&1; then
  source <(wget -qO- "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/core.func")
  load_functions
fi
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/lib/tools.func")
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/error_handler.func")

APP="Immich Power Tools"
APP_TYPE="addon"

header_info "$APP"
color
catch_errors

if [[ ! -f /opt/immich/.env ]] || ! systemctl is-active --quiet immich-web; then
  msg_error "Immich is not installed or not running. Install the Immich LXC first, then run this addon inside it."
  exit 1
fi

if [[ "$(cut -d. -f1 ~/.immich 2>/dev/null)" -lt 3 ]]; then
  msg_error "Immich Power Tools needs Immich 3.0 or newer. Update the Immich LXC first."
  exit 1
fi

MEM_MB=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)
if ((MEM_MB < 4096)); then
  msg_error "Insufficient memory: ${MEM_MB} MB detected. At least 4096 MB RAM is required to build Immich Power Tools."
  exit 1
fi

get_lxc_ip

function build_power_tools() {
  cd /opt/immich-power-tools || exit 1
  $STD bun install --frozen-lockfile
  VERSION="$(cat ~/.immich-power-tools)" NEXT_TELEMETRY_DISABLED=1 $STD npm run build
  cp -r public .next/standalone/
  cp -r .next/static .next/standalone/.next/
  mkdir -p .next/standalone/src/db
  cp -r src/db/migrations .next/standalone/src/db/
  cp -r node_modules/@libsql node_modules/libsql .next/standalone/node_modules/
  rm -rf node_modules .next/cache
  $STD bun pm cache rm
}

function install_ui() {
  if [[ -z "${var_immich_api_key:-}" ]]; then
    var_immich_api_key=$(prompt_input "Immich API key (empty = log in with your Immich account):" "" 120)
  fi

  NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
  fetch_and_deploy_gh_release "immich-power-tools" "immich-power-tools/immich-power-tools" "tarball"

  msg_info "Building Immich Power Tools"
  build_power_tools
  msg_ok "Built Immich Power Tools"

  msg_info "Configuring Immich Power Tools"
  IMMICH_PORT=$(sed -n 's/^IMMICH_PORT=//p' /opt/immich/.env)
  DB_PORT=$(sed -n 's/^DB_PORT=//p' /opt/immich/.env)
  mkdir -p /opt/immich-power-tools_data
  cat <<EOF >/opt/immich-power-tools_data/.env
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
PORT=8001
HOSTNAME=0.0.0.0
APP_DB_PATH=/opt/immich-power-tools_data/app.db

IMMICH_URL=http://127.0.0.1:${IMMICH_PORT:-2283}
EXTERNAL_IMMICH_URL=http://${LOCAL_IP}:${IMMICH_PORT:-2283}
# Immich > Account Settings > API Keys (all permissions). Empty = log in with an Immich account.
# With a key there is no login: everyone reaching port 8001 acts as the key's owner.
IMMICH_API_KEY=${var_immich_api_key}

DB_HOST=$(sed -n 's/^DB_HOSTNAME=//p' /opt/immich/.env)
DB_PORT=${DB_PORT:-5432}
$(grep -E '^DB_(USERNAME|PASSWORD|DATABASE_NAME)=' /opt/immich/.env)

SECURE_COOKIE=false
JWT_SECRET=$(openssl rand -hex 32)
POWER_TOOLS_ENDPOINT_URL=http://${LOCAL_IP}:8001

# Optional, any OpenAI-compatible API for "Find"
# AI_API_KEY=
# AI_BASE_URL=https://api.openai.com/v1
# AI_MODEL=gpt-4o-mini
EOF
  chmod 600 /opt/immich-power-tools_data/.env

  cat <<EOF >/etc/systemd/system/immich-power-tools.service
[Unit]
Description=Immich Power Tools
After=network.target postgresql.service immich-web.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/immich-power-tools/.next/standalone
EnvironmentFile=/opt/immich-power-tools_data/.env
ExecStart=/usr/bin/node /opt/immich-power-tools/.next/standalone/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now immich-power-tools
  msg_ok "Configured Immich Power Tools"

  msg_ok "Immich Power Tools installed at http://${LOCAL_IP}:8001"
  if [[ -n "$var_immich_api_key" ]]; then
    msg_warn "Immich Power Tools has no login with an API key: everyone reaching port 8001 acts as the key's owner"
  else
    echo -e "${INFO}${YW} Log in with your Immich account, or set IMMICH_API_KEY in /opt/immich-power-tools_data/.env and run: systemctl restart immich-power-tools${CL}"
  fi
}

function uninstall_ui() {
  msg_info "Uninstalling Immich Power Tools"
  systemctl disable -q --now immich-power-tools
  rm -f /etc/systemd/system/immich-power-tools.service
  systemctl daemon-reload
  rm -rf /opt/immich-power-tools /opt/immich-power-tools_data ~/.immich-power-tools
  msg_ok "Uninstalled Immich Power Tools"
}

function update_ui() {
  if check_for_gh_release "immich-power-tools" "immich-power-tools/immich-power-tools"; then
    msg_info "Stopping Immich Power Tools"
    systemctl stop immich-power-tools
    msg_ok "Stopped Immich Power Tools"

    NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "immich-power-tools" "immich-power-tools/immich-power-tools" "tarball"

    msg_info "Building Immich Power Tools"
    build_power_tools
    msg_ok "Built Immich Power Tools"

    msg_info "Starting Immich Power Tools"
    systemctl start immich-power-tools
    msg_ok "Started Immich Power Tools"
    msg_ok "Updated Immich Power Tools"
  fi
}

if [[ -f /etc/systemd/system/immich-power-tools.service ]]; then
  read -r -p "Update (1), Uninstall (2), Cancel (3)? [1/2/3]: " action
  action="${action//[[:space:]]/}"
  case "$action" in
  1) update_ui ;;
  2) uninstall_ui ;;
  3) msg_warn "Cancelled" ;;
  *) msg_error "Invalid input" ;;
  esac
else
  read -r -p "Install Immich Power Tools? (y/n): " answer
  answer="${answer//[[:space:]]/}"
  if [[ "${answer,,}" =~ ^(y|yes)$ ]]; then
    install_ui
  else
    msg_warn "Installation of Immich Power Tools skipped"
  fi
fi
