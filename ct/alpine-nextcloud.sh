#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nextcloud.com/

APP="Alpine-Nextcloud"
var_tags="${var_tags:-alpine;cloud}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-2}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  if [[ ! -d /usr/share/webapps/nextcloud ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! apk -e info newt >/dev/null 2>&1; then
    apk add -q newt
  fi
  while true; do
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 3 \
      "1" "Nextcloud Login Credentials" ON \
      "2" "Renew Self-signed Certificate" OFF \
      3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status == 1 ]; then
      clear
      exit-script
    fi
    header_info
    case $CHOICE in
    1)
      cat nextcloud.creds
      exit
      ;;
    2)
      openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/nextcloud-selfsigned.key -out /etc/ssl/certs/nextcloud-selfsigned.crt -subj "/C=US/O=Nextcloud/OU=Domain Control Validated/CN=nextcloud.local" >/dev/null 2>&1
      rc-service nginx restart
      exit
      ;;
    esac
  done
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}https://${IP}${CL} \n"
