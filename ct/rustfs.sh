#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: halilugur
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://rustfs.com/

# App Default Values
APP="RustFS"
var_tags="filesystem;storage"
var_cpu="2"
var_ram="2048"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # Check if installation exists
  if [[ ! -f /lib/systemd/system/rustfs.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ${APP}"
  msg_warn "RustFS uses an external installer from https://rustfs.com/"
  msg_warn "Running the installer to check for updates..."
  echo "3" | $STD bash <(curl -fsSL https://rustfs.com/install_rustfs.sh)
  msg_ok "Updated ${APP}"

  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
