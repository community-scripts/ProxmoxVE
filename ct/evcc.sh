#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://evcc.io/en/

APP="evcc"
var_tags="${var_tags:-solar;ev;automation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if ! command -v evcc >/dev/null 2>&1; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if [[ -f /etc/apt/sources.list.d/evcc-stable.list ]]; then
    setup_deb822_repo \
      "evcc-stable" \
      "https://dl.evcc.io/public/evcc/stable/gpg.EAD5D0E07B0EC0FD.key" \
      "https://dl.evcc.io/public/evcc/stable/deb/debian/" \
      "$(get_os_info codename)" \
      "main"
  fi
  msg_info "Updating evcc LXC"
  $STD apt update
  $STD apt --only-upgrade install -y evcc
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7070${CL}"
