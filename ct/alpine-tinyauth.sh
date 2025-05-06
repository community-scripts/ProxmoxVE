#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/steveiliop56/tinyauth

APP="Alpine-tinyauth"
var_tags="${var_tags:-alpine;auth}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-3}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.21}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  if [[ ! -d /opt/tinyauth ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  msg_info "Updating Alpine Packages"
  $STD apk update
  $STD apk upgrade
  msg_ok "Updated Alpine Packages"

  msg_info "Updating tinyauth"
  RELEASE=$(curl -s https://api.github.com/repos/steveiliop56/tinyauth/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [ "${RELEASE}" != "$(cat /opt/tinyauth_version.txt)" ] || [ ! -f /opt/tinyauth_version.txt ]; then
    $STD service tinyauth stop
    temp_file=$(mktemp)
    cp /opt/tinyauth/.env /opt
    rm -rf /opt/tinyauth
    mkdir -p /opt/tinyauth
    curl -fsSL "https://github.com/steveiliop56/tinyauth/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
    tar -xzf "$temp_file" -C /opt/tinyauth --strip-components=1
    cd /opt/tinyauth/frontend
    $STD bun install
    $STD bun run build
    mv dist /opt/tinyauth/internal/assets/
    cd /opt/tinyauth
    $STD go mod download
    CGO_ENABLED=0 go build -ldflags "-s -w"
    cp /opt/.env /opt/tinyauth
    echo "${RELEASE}" >/opt/tinyauth_version.txt
    rm -f "$temp_file"
    msg_info "Restarting tinyauth"
    $STD service tinyauth start
    msg_ok "Restarted tinyauth"
    msg_ok "Updated tinyauth"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
