#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024
# Author: thisisjeron
# License: MIT
# Source: https://calibre-ebook.com

# App Default Values
APP="Calibre-Server"
var_tags="ebook"
var_cpu="2"
var_ram="1024"
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

  # Check if installed
  if [[ ! -f /etc/systemd/system/calibre-server.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping ${APP}"
  systemctl stop calibre-server
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} container packages"
  apt-get update &>/dev/null
  apt-get -y upgrade &>/dev/null
  msg_ok "Container packages updated"

  # Potentially re-run the official calibre script to ensure most recent version
  # to keep logic consistent with how other scripts handle updates.
  msg_info "Updating Calibre (latest)"
  wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin &>/dev/null
  msg_ok "Updated Calibre"

  msg_info "Starting ${APP}"
  systemctl start calibre-server
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8180${CL}" 