#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://redis.io/

APP="Alpine-Redis"
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
  LXCIP=$(ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)

  CHOICE=$(msg_menu "Redis Management" \
    "1" "Update Redis" \
    "2" "Allow 0.0.0.0 for listening" \
    "3" "Allow only ${LXCIP} for listening")

  case $CHOICE in
  1)
    msg_info "Updating Redis"
    apk update && apk upgrade redis
    rc-service redis restart
    msg_ok "Updated successfully!"
    exit
    ;;
  2)
    msg_info "Setting Redis to listen on all interfaces"
    sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis.conf
    rc-service redis restart
    msg_ok "Redis now listens on all interfaces!"
    exit
    ;;
  3)
    msg_info "Setting Redis to listen only on ${LXCIP}"
    sed -i "s/^bind .*/bind ${LXCIP}/" /etc/redis.conf
    rc-service redis restart
    msg_ok "Redis now listens only on ${LXCIP}!"
    exit
    ;;
  esac
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${APP} should be reachable on port 6379.
         ${BL}redis-cli -h ${IP} -p 6379${CL} \n"
