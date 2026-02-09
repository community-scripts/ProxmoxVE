#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: hoholms
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/grafana/loki

APP="Alpine-Loki"
var_tags="${var_tags:-alpine;monitoring}"
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
  LXCIP=$(ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)

  CHOICE=$(msg_menu "Loki Update Options" \
    "1" "Check for Loki Updates" \
    "2" "Allow 0.0.0.0 for listening" \
    "3" "Allow only ${LXCIP} for listening")

  case $CHOICE in
  1)
    $STD apk -U upgrade
    msg_ok "Updated successfully!"
    exit
    ;;
  2)
    sed -i -e "s/cfg:server.http_addr=.*/cfg:server.http_addr=0.0.0.0/g" /etc/conf.d/loki
    service loki restart
    msg_ok "Allowed listening on all interfaces!"
    exit
    ;;
  3)
    sed -i -e "s/cfg:server.http_addr=.*/cfg:server.http_addr=$LXCIP/g" /etc/conf.d/loki
    service loki restart
    msg_ok "Allowed listening only on ${LXCIP}!"
    exit
    ;;
  esac
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:3100${CL} \n"
echo -e "Promtail should be reachable by going to the following URL.
         ${BL}http://${IP}:9080${CL} \n"
