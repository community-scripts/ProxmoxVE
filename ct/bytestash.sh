#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jordan-dalby/ByteStash

APP="ByteStash"
var_tags="${var_tags:-code}"
var_disk="${var_disk:-4}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/bytestash ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/jordan-dalby/ByteStash/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat ~/.bytestash 2>/dev/null)" ]] || [[ ! -f ~/.bytestash ]]; then

    read -rp "${TAB3}Did you make a backup via application WebUI? (y/n): " backuped
    if [[ "$backuped" =~ ^[Yy]$ ]]; then
      msg_info "Stopping Services"
      systemctl stop bytestash-backend
      systemctl stop bytestash-frontend
      msg_ok "Services Stopped"

      rm -rf /opt/bytestash
      fetch_and_deploy_gh_release "bytestash" "jordan-dalby/ByteStash"

      msg_info "Configuring ByteStash"
      cd /opt/bytestash/server
      $STD npm install
      cd /opt/bytestash/client
      $STD npm install
      msg_ok "Updated ${APP}"

      msg_info "Starting Services"
      systemctl start bytestash-backend
      systemctl start bytestash-frontend
      msg_ok "Started Services"
    else
      msg_error "PLEASE MAKE A BACKUP FIRST!"
      exit
    fi
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
