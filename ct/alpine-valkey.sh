#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: pshankinclarke (lazarillo)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://valkey.io/

APP="Alpine-Valkey"
var_tags="${var_tags:-alpine;database}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-1}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  if ! apk -e info newt >/dev/null 2>&1; then
    apk add -q newt
  fi
  LXCIP=$(ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
  while true; do
    CHOICE=$(
      whiptail --backtitle "Proxmox VE Helper Scripts" --title "Valkey Management" --menu "Select option" 11 58 3 \
        "1" "Update Valkey" \
        "2" "Allow 0.0.0.0 for listening" \
        "3" "Allow only ${LXCIP} for listening" 3>&2 2>&1 1>&3
    )
    exit_status=$?
    if [ $exit_status == 1 ]; then
      clear
      exit-script
    fi
    header_info
    case $CHOICE in
    1)
      msg_info "Updating Valkey"
      apk update && apk upgrade valkey
      rc-service valkey restart
      msg_ok "Updated Valkey"
      msg_ok "Updated successfully!"
      exit
      ;;
    2)
      msg_info "Setting Valkey to listen on all interfaces"
      sed -i 's/^bind .*/bind 0.0.0.0/' /etc/valkey/valkey.conf
      rc-service valkey restart
      msg_ok "Valkey now listens on all interfaces!"
      exit
      ;;
    3)
      msg_info "Setting Valkey to listen only on ${LXCIP}"
      sed -i "s/^bind .*/bind ${LXCIP}/" /etc/valkey/valkey.conf
      rc-service valkey restart
      msg_ok "Valkey now listens only on ${LXCIP}!"
      exit
      ;;
    esac
  done
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${APP} should be reachable on port 6379.
         ${BL}valkey-cli -h ${IP} -p 6379${CL} \n"
