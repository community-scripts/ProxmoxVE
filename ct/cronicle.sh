#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://cronicle.net/

APP="Cronicle"
var_tags="${var_tags:-task-scheduler}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 2 \
    "1" "Update ${APP}" ON \
    "2" "Install ${APP} Worker" OFF \
    3>&1 1>&2 2>&3)

  if [ "$UPD" == "1" ]; then
    if [[ ! -d /opt/cronicle ]]; then
      msg_error "No ${APP} Installation Found!"
      exit
    fi
    NODE_VERSION="22" setup_nodejs

    msg_info "Updating ${APP}"
    $STD /opt/cronicle/bin/control.sh upgrade
    msg_ok "Updated ${APP}"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    NODE_VERSION="22" setup_nodejs
    if check_for_gh_release "cronicle" "jhuckaby/Cronicle"; then
      IP=$(hostname -I | awk '{print $1}')
      msg_info "Installing Dependencies"
      $STD apt-get install -y \
        git \
        build-essential \
        ca-certificates \
        gnupg2
      msg_ok "Installed Dependencies"

      NODE_VERSION="22" setup_nodejs
      fetch_and_deploy_gh_release "cronicle" "jhuckaby/Cronicle"

      msg_info "Configuring Cronicle Worker"
      cd /opt/cronicle
      $STD npm install
      $STD node bin/build.js dist
      sed -i "s/localhost:3012/${IP}:3012/g" /opt/cronicle/conf/config.json
      $STD /opt/cronicle/bin/control.sh start
      $STD cp /opt/cronicle/bin/cronicled.init /etc/init.d/cronicled
      chmod 775 /etc/init.d/cronicled
      $STD update-rc.d cronicled defaults
      msg_ok "Installed Cronicle Worker"

      echo -e "\n Add Masters secret key to /opt/cronicle/conf/config.json \n"
      exit
    fi
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3012${CL}"
