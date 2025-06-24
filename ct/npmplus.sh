#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ZoeyVid/NPMplus

APP="NPMplus"
var_tags="${var_tags:-proxy;nginx}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-3}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE MODE" --radiolist --cancel-button Exit-Script "Spacebar = Select" 14 60 2 \
    "1" "Check for Alpine Updates" OFF \
    "2" "Update NPMplus Docker Container" ON \
    3>&1 1>&2 2>&3)

  header_info "$APP"

  case "$UPD" in
  "1")
    msg_info "Updating Alpine OS"
    $STD apk -U upgrade
    msg_ok "System updated"
    exit
    ;;
  "2")
    msg_info "Updating NPMplus Container"
    cd /opt
    msg_info "Pulling latest container image"
    $STD docker compose pull
    msg_info "Recreating container"
    $STD docker compose up -d
    msg_ok "NPMplus container updated"
    exit
    ;;
  esac
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:81${CL}"
