#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NousResearch/hermes-agent

APP="Hermes"
var_tags="${var_tags:-ai;agent;llm;automation}"
var_cpu="${var_cpu:-8}"
var_ram="${var_ram:-16384}"
var_disk="${var_disk:-50}"
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

  if [[ ! -d /opt/hermes-agent ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ ! -x /opt/hermes-agent/.venv/bin/hermes ]]; then
    msg_error "Hermes executable not found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop hermes-agent
  msg_ok "Stopped Service"

  msg_info "Backing up Configuration"
  cp -r /root/.hermes /opt/hermes_backup 2>/dev/null || true
  msg_ok "Backed up Configuration"

  msg_info "Updating Hermes Agent"
  cd /opt/hermes-agent || exit
  export VIRTUAL_ENV="/opt/hermes-agent/.venv"
  $STD /opt/hermes-agent/.venv/bin/hermes update
  msg_ok "Updated Hermes Agent"

  msg_info "Restoring Configuration"
  cp -r /opt/hermes_backup/. /root/.hermes 2>/dev/null || true
  rm -rf /opt/hermes_backup
  msg_ok "Restored Configuration"

  msg_info "Starting Service"
  systemctl start hermes-agent
  msg_ok "Started Service"
  msg_ok "Updated successfully!"

  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using use the CLI: hermes${CL}"
