#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

# App Default Values
APP="Forgejo"
var_tags="git"
var_cpu="2"
var_ram="2048"
var_disk="10"
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
  if [[ ! -d /opt/forgejo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Stopping ${APP}"
  systemctl stop forgejo
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP}"
  RELEASE=$(curl -s https://codeberg.org/api/v1/repos/forgejo/forgejo/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/^v//')
  wget -qO forgejo-$RELEASE-linux-amd64 "https://codeberg.org/forgejo/forgejo/releases/download/v${RELEASE}/forgejo-${RELEASE}-linux-amd64"
  rm -rf /opt/forgejo/*
  cp -r forgejo-$RELEASE-linux-amd64 /opt/forgejo/forgejo-$RELEASE-linux-amd64
  chmod +x /opt/forgejo/forgejo-$RELEASE-linux-amd64
  ln -sf /opt/forgejo/forgejo-$RELEASE-linux-amd64 /usr/local/bin/forgejo
  msg_ok "Updated ${APP}"

  msg_info "Cleaning"
  rm -rf forgejo-$RELEASE-linux-amd64
  msg_ok "Cleaned"

  msg_info "Starting ${APP}"
  systemctl start forgejo
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"