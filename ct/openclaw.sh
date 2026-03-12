#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BIllyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw

APP="openclaw"
var_tags="${var_tags:-ai;assistant;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -x /usr/bin/openclaw ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Get current version
  CURRENT_VERSION=$(openclaw --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
  
  # Get latest version from npm
  LATEST_VERSION=$(npm view openclaw version 2>/dev/null || echo "unknown")

  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    msg_ok "OpenClaw is already up to date (v${CURRENT_VERSION})"
    exit
  fi

  if [[ "$LATEST_VERSION" == "unknown" ]]; then
    msg_error "Unable to check for updates. Please try again later."
    exit
  fi

  msg_info "Updating OpenClaw from v${CURRENT_VERSION} to v${LATEST_VERSION}"
  
  msg_info "Stopping Service"
  systemctl stop openclaw
  msg_ok "Stopped Service"

  msg_info "Backing up Configuration"
  if [[ -d /root/.openclaw ]]; then
    cp -r /root/.openclaw /tmp/openclaw_backup
  fi
  msg_ok "Backed up Configuration"

  msg_info "Updating OpenClaw"
  $STD npm update -g openclaw
  msg_ok "Updated OpenClaw"

  msg_info "Restoring Configuration"
  if [[ -d /tmp/openclaw_backup ]]; then
    cp -r /tmp/openclaw_backup/. /root/.openclaw 2>/dev/null || true
    rm -rf /tmp/openclaw_backup
  fi
  msg_ok "Restored Configuration"

  msg_info "Starting Service"
  systemctl start openclaw
  msg_ok "Started Service"
  
  msg_ok "Updated successfully to v${LATEST_VERSION}!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:18789${CL}"
echo -e "${INFO}${YW} Gateway WebSocket: ws://${IP}:18789${CL}"
