#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://caddyserver.com/

APP="Caddy"
var_tags="${var_tags:-webserver}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /etc/caddy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating $APP LXC"
  $STD apt-get update
  $STD apt-get -y upgrade
  msg_ok "Updated successfully!"
  msg_ok "Updated $APP LXC"

  if command -v xcaddy >/dev/null 2>&1; then
    setup_go
    msg_info "Updating xCaddy"
    cd /opt
    RELEASE=$(curl -fsSL https://api.github.com/repos/caddyserver/xcaddy/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
    VERSION="${RELEASE#v}"
    curl -fsSL "https://github.com/caddyserver/xcaddy/releases/download/${RELEASE}/xcaddy_${VERSION}_linux_amd64.deb" -o "xcaddy_${VERSION}_linux_amd64.deb"
    $STD dpkg -i "xcaddy_${VERSION}_linux_amd64.deb"
    rm -f "xcaddy_${VERSION}_linux_amd64.deb"
    $STD xcaddy build
    msg_ok "Updated xCaddy"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
