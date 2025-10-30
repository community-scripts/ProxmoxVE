#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://alpinelinux.org/

APP="Alpine"
var_tags="${var_tags:-os;alpine}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-1}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  UPD=$(
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 1 \
      "1" "Check for Alpine Updates" ON \
      3>&1 1>&2 2>&3
  )

  header_info
  if [ "$UPD" == "1" ]; then
    $STD apk -U upgrade
    msg_ok "Updated successfully!"
    exit 0
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
