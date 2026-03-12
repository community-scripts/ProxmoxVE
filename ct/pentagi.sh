#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: Heretek-AI
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/vxcontrol/pentagi

APP="PentAGI"
var_tags="${var_tags:-ai;security;pentest;automation}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
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

  if [[ ! -d /opt/pentagi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ ! -f /opt/pentagi/docker-compose.yml ]]; then
    msg_error "No ${APP} docker-compose.yml Found!"
    exit
  fi

  msg_info "Stopping ${APP} Services"
  systemctl stop pentagi
  msg_ok "Stopped ${APP} Services"

  msg_info "Backing up Configuration"
  cp /opt/pentagi/.env /opt/pentagi_env_backup
  msg_ok "Backed up Configuration"

  msg_info "Updating ${APP} Container Images"
  cd /opt/pentagi || exit
  $STD docker compose pull
  msg_ok "Updated ${APP} Container Images"

  msg_info "Restoring Configuration"
  cp /opt/pentagi_env_backup /opt/pentagi/.env
  msg_ok "Restored Configuration"

  msg_info "Starting ${APP} Services"
  systemctl start pentagi
  msg_ok "Started ${APP} Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8443${CL}"
echo -e "${INFO}${YW} Default credentials: admin@pentagi.com / admin${CL}"
echo -e "${INFO}${YW} Configure your LLM provider API keys in Settings${CL}"
