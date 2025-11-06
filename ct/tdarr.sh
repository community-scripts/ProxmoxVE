#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://home.tdarr.io/

APP="Tdarr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/tdarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating Tdarr"
  $STD apt update
  $STD apt upgrade -y
  rm -rf /opt/tdarr/Tdarr_Updater
  cd /opt/tdarr
  RELEASE=$(curl -fsSL https://f000.backblazeb2.com/file/tdarrs/versions.json | grep -oP '(?<="Tdarr_Updater": ")[^"]+' | grep linux_x64 | head -n 1)
  curl -fsSL "$RELEASE" -o Tdarr_Updater.zip
  $STD unzip Tdarr_Updater.zip
  chmod +x Tdarr_Updater
  $STD ./Tdarr_Updater
  msg_ok "Updated Tdarr"

  msg_info "Cleaning up"
  rm -rf /opt/tdarr/Tdarr_Updater.zip
  msg_ok "Cleaned up"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8265${CL}"
