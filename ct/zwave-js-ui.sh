#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
 _____                                  _______    __  ______
/__  /_      ______ __   _____         / / ___/   / / / /  _/
  / /| | /| / / __ `/ | / / _ \   __  / /\__ \   / / / // /  
 / /_| |/ |/ / /_/ /| |/ /  __/  / /_/ /___/ /  / /_/ // /   
/____/__/|__/\__,_/ |___/\___/   \____//____/   \____/___/   
                                                             
EOF
}
header_info
echo -e "Loading..."
APP="Zwave-JS-UI"
var_disk="4"
var_cpu="2"
var_ram="1024"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="0"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/zwave-js-ui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/zwave-js/zwave-js-ui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  msg_info "Stopping Z-wave JS UI"
  systemctl stop zwave-js-ui.service
  msg_ok "Stopped Z-wave JS UI"

  msg_info "Updating Z-wave JS UI"
  wget https://github.com/zwave-js/zwave-js-ui/releases/download/${RELEASE}/zwave-js-ui-${RELEASE}-linux.zip &>/dev/null
  unzip zwave-js-ui-${RELEASE}-linux.zip &>/dev/null
  \cp -R zwave-js-ui-linux /opt/zwave-js-ui
  service_path="/etc/systemd/system/zwave-js-ui.service"
  echo "[Unit]
  Description=zwave-js-ui
  Wants=network-online.target
  After=network-online.target
  [Service]
  User=root
  WorkingDirectory=/opt/zwave-js-ui
  ExecStart=/opt/zwave-js-ui/zwave-js-ui-linux
  [Install]
  WantedBy=multi-user.target" >$service_path
  msg_ok "Updated Z-wave JS UI"

  msg_info "Starting Z-wave JS UI"
  systemctl enable --now zwave-js-ui.service
  msg_ok "Started Z-wave JS UI"

  msg_info "Cleanup"
  rm -rf zwave-js-ui-${RELEASE}-linux.zip zwave-js-ui-linux store
  msg_ok "Cleaned"
  msg_ok "Updated Successfully!\n"
  exit
}

start
build_container
description

echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8091${CL} \n"
