#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://traefik.io/

# App Default Values
APP="Traefik"
var_tags="proxy"
var_cpu="1"
var_ram="512"
var_disk="2"
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
  if [[ ! -f /etc/systemd/system/traefik.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/traefik/traefik/releases | grep -oP '"tag_name":\s*"v\K[\d.]+?(?=")' | sort -V | tail -n 1)
  msg_info "Updating $APP LXC"
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    wget -q https://github.com/traefik/traefik/releases/download/v${RELEASE}/traefik_v${RELEASE}_linux_amd64.tar.gz
    tar -C /tmp -xzf traefik*.tar.gz
    mv /tmp/traefik /usr/bin/
    rm -rf traefik*.tar.gz
    systemctl restart traefik.service
    echo "${RELEASE}" >/opt/${APP}_version.txt
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"