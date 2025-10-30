#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nodered.org/

APP="Node-Red"
var_tags="${var_tags:-automation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /root/.node-red ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 2 \
    "1" "Update ${APP}" ON \
    "2" "Install Themes" OFF \
    3>&1 1>&2 2>&3)
  if [ "$UPD" == "1" ]; then
    NODE_VERSION="22" setup_nodejs

    msg_info "Stopping Service"
    systemctl stop nodered
    msg_ok "Stopped Service"

    msg_info "Updating Node-Red"
    $STD npm install -g --unsafe-perm node-red
    msg_ok "Updated Node-Red"

    msg_info "Starting Service"
    systemctl start nodered
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    THEME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "NODE-RED THEMES" --radiolist --cancel-button Exit-Script "Choose Theme" 15 58 6 \
      "aurora" "" OFF \
      "cobalt2" "" OFF \
      "dark" "" OFF \
      "dracula" "" OFF \
      "espresso-libre" "" OFF \
      "github-dark" "" OFF \
      "github-dark-default" "" OFF \
      "github-dark-dimmed" "" OFF \
      "midnight-red" "" ON \
      "monoindustrial" "" OFF \
      "monokai" "" OFF \
      "monokai-dimmed" "" OFF \
      "noctis" "" OFF \
      "oceanic-next" "" OFF \
      "oled" "" OFF \
      "one-dark-pro" "" OFF \
      "one-dark-pro-darker" "" OFF \
      "solarized-dark" "" OFF \
      "solarized-light" "" OFF \
      "tokyo-night" "" OFF \
      "tokyo-night-light" "" OFF \
      "tokyo-night-storm" "" OFF \
      "totallyinformation" "" OFF \
      "zenburn" "" OFF \
      3>&1 1>&2 2>&3)
    header_info
    msg_info "Installing ${THEME} Theme"
    cd /root/.node-red
    sed -i 's|// theme: ".*",|theme: "",|g' /root/.node-red/settings.js
    $STD npm install @node-red-contrib-themes/theme-collection
    sed -i "{s/theme: ".*"/theme: '${THEME}',/g}" /root/.node-red/settings.js
    systemctl restart nodered
    msg_ok "Installed ${THEME} Theme"
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1880${CL}"
