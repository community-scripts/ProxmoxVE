#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

APP="Alpine-RustDeskServer"
var_tags="${var_tags:-alpine;monitoring}"
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
  header_info
  if [[ ! -d /opt/rustdesk-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  APIRELEASE=$(curl -s https://api.github.com/repos/lejianwen/rustdesk-api/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  RELEASE=$(curl -s https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [ "${RELEASE}" != "$(cat ~/.rustdesk-server 2>/dev/null)" ] || [ ! -f ~/.rustdesk-server ]; then
    msg_info "Updating RustDesk Server to v${RELEASE}"
    $STD apk -U upgrade
    $STD service rustdesk-server-hbbs stop
    $STD service rustdesk-server-hbbr stop
    temp_file1=$(mktemp)
    curl -fsSL "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-linux-amd64.zip" -o "$temp_file1"
    $STD unzip "$temp_file1"
    cp -r amd64/* /opt/rustdesk-server/
    echo "${RELEASE}" >~/.rustdesk-server
    $STD service rustdesk-server-hbbs start
    $STD service rustdesk-server-hbbr start
    rm -rf amd64
    rm -f $temp_file1
    msg_ok "Updated RustDesk Server successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  if [ "${APIRELEASE}" != "$(cat ~/.rustdesk-api)" ] || [ ! -f ~/.rustdesk-api ]; then
    msg_info "Updating RustDesk API to v${APIRELEASE}"
    $STD service rustdesk-api stop
    temp_file2=$(mktemp)
    curl -fsSL "https://github.com/lejianwen/rustdesk-api/releases/download/v${APIRELEASE}/linux-amd64.tar.gz" -o "$temp_file2"
    $STD tar zxvf "$temp_file2"
    cp -r release/* /opt/rustdesk-api
    echo "${APIRELEASE}" >~/.rustdesk-api
    $STD service rustdesk-api start
    rm -rf release
    rm -f $temp_file2
    msg_ok "Updated RustDesk API"
  else
    msg_ok "No update required. RustDesk API is already at v${APIRELEASE}"
  fi
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:21114${CL}"
