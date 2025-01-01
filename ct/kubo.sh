#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: ulmentflam
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ipfs/kubo

# App Default Values
APP="Kubo"
var_tags="sharing"
var_cpu="2"
var_ram="4096"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /usr/local/kubo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(wget -q https://github.com/ipfs/kubo/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Updating $APP LXC"
    apt-get update &>/dev/null
    apt-get -y upgrade &>/dev/null
    wget -q "https://github.com/ipfs/kubo/releases/download/${RELEASE}/kubo_${RELEASE}_linux-amd64.tar.gz"
    tar -xzf "kubo_${RELEASE}_linux-amd64.tar.gz" -C /usr/local
    systemctl restart ipfs.service
    echo "${RELEASE}" >/opt/${APP}_version.txt
    rm "kubo_${RELEASE}_linux-amd64.tar.gz"
    msg_ok "Updated $APP LXC"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5001/webui${CL}"