#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nextcloud.com/

APP="Alpine-Nextcloud"
var_tags="${var_tags:-alpine;cloud}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-2}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
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

  CHOICE=$(msg_menu "Nextcloud Options" \
    "1" "Update Alpine Packages" \
    "2" "Nextcloud Login Credentials" \
    "3" "Renew Self-signed Certificate")

  case $CHOICE in
  1)
    msg_info "Updating Alpine Packages"
    $STD apk -U upgrade
    msg_ok "Updated Alpine Packages"
    msg_ok "Updated successfully!"
    exit
    ;;
  2)
    cat nextcloud.creds
    exit
    ;;
  3)
    openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/nextcloud-selfsigned.key -out /etc/ssl/certs/nextcloud-selfsigned.crt -subj "/C=US/O=Nextcloud/OU=Domain Control Validated/CN=nextcloud.local" >/dev/null 2>&1
    rc-service nginx restart
    msg_ok "Renewed self-signed certificate"
    exit
    ;;
  esac
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}https://${IP}${CL} \n"
