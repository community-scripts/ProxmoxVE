#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nodered.org/

# App Default Values
APP="Node-Red"
var_tags="automation"
var_cpu="1"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
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
    if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
      if ! command -v npm >/dev/null 2>&1; then
        msg_info "Installing NPM"
        apt-get install -y npm >/dev/null 2>&1
        msg_ok "Installed NPM"
      fi
    fi
    msg_info "Stopping ${APP}"
    systemctl stop nodered
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP}"
    npm install -g --unsafe-perm node-red &>/dev/null
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start nodered
    msg_ok "Started ${APP}"
    msg_ok "Update Successful"
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
    npm install @node-red-contrib-themes/theme-collection &>/dev/null
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