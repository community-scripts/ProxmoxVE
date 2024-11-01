#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
 _____   _       __             ___   __  _______  ____________
/__  /  (_)___ _/ /_  ___  ___ |__ \ /  |/  / __ \/_  __/_  __/
  / /  / / __  / __ \/ _ \/ _ \__/ // /|_/ / / / / / /   / /   
 / /__/ / /_/ / /_/ /  __/  __/ __// /  / / /_/ / / /   / /    
/____/_/\__, /_.___/\___/\___/____/_/  /_/\___\_\/_/   /_/     
       /____/ Alpine
 
EOF
}
header_info
echo -e "Loading..."
APP="Alpine-Zigbee2MQTT"
var_disk="0.3"
var_cpu="1"
var_ram="256"
var_os="alpine"
var_version="3.19"
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
  if ! apk -e info newt >/dev/null 2>&1; then
    apk add -q newt
  fi
  while true; do
    CHOICE=$(
      whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --menu "Select option" 11 58 1 \
        "1" "Check for Zigbee2MQTT Updates" 3>&2 2>&1 1>&3
    )
    exit_status=$?
    if [ $exit_status == 1 ]; then
      clear
      exit-script
    fi
    header_info
    case $CHOICE in
    1)
      apk update && apk upgrade
      exit
      ;;
    esac
  done
}

start
build_container
description

msg_ok "Completed Successfully!\n"
