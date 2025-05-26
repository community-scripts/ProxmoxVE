#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Omar Minaya
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kasmweb.com/docs/latest/index.html

APP="Kasm"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4192}"
var_disk="${var_disk:-30}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"
var_fuse="${var_fuse:-yes}"
var_tun="${var_tun:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /var ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating $APP LXC"
  cd /tmp
  KASM_VERSION=$(curl -fsSL 'https://www.kasmweb.com/downloads' | grep -o 'https://kasm-static-content.s3.amazonaws.com/kasm_release_[^"]*\.tar\.gz' | head -n 1 | sed -E 's/.*release_(.*)\.tar\.gz/\1/')
  curl -O "https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_VERSION}.tar.gz"
  tar -xf "kasm_release_${KASM_VERSION}.tar.gz"
  $STD sudo bash kasm_release/upgrade.sh

  $STD apt-get update
  $STD apt-get -y upgrade
  $STD rm -f "/tmp/kasm_release_${KASM_VERSION}.tar.gz"
  msg_ok "Updated $APP LXC"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
