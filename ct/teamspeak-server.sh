#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tremor021 (Slaviša Arežina)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://teamspeak.com/en/

APP="Teamspeak-Server"
var_tags="${var_tags:-voice;communication}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-256}"
  var_disk="${var_disk:-2}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-2}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /opt/teamspeak-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://teamspeak.com/en/downloads/#server | grep -oP 'teamspeak3-server_linux_amd64-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [[ "${RELEASE}" != "$(cat ~/.teamspeak-server 2>/dev/null)" ]] || [[ ! -f ~/.teamspeak-server ]]; then
    msg_info "Stopping Service"
    systemctl stop teamspeak-server
    msg_ok "Stopped Service"

    msg_info "Updating Teamspeak Server"
    curl -fsSL "https://files.teamspeak-services.com/releases/server/${RELEASE}/teamspeak3-server_linux_amd64-${RELEASE}.tar.bz2" -o ts3server.tar.bz2
    tar -xf ./ts3server.tar.bz2
    cp -ru teamspeak3-server_linux_amd64/* /opt/teamspeak-server/
    rm -f ~/ts3server.tar.bz*
    echo "${RELEASE}" >~/.teamspeak-server
    msg_ok "Updated Teamspeak Server"

    msg_info "Starting Service"
    systemctl start teamspeak-server
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "Already up to date"
  fi
}

update_alpine() {
  if [[ ! -d /opt/teamspeak-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://teamspeak.com/en/downloads/#server | sed -n 's/.*teamspeak3-server_linux_amd64-\([0-9.]*[0-9]\).*/\1/p' | awk 'NR==1')

  if [ "${RELEASE}" != "$(cat ~/.teamspeak-server)" ] || [ ! -f ~/.teamspeak-server ]; then
    msg_info "Updating ${APP} LXC"
    $STD apk -U upgrade
    $STD service teamspeak stop
    curl -fsSL "https://files.teamspeak-services.com/releases/server/${RELEASE}/teamspeak3-server_linux_amd64-${RELEASE}.tar.bz2" -o ts3server.tar.bz2
    tar -xf ./ts3server.tar.bz2
    cp -ru teamspeak3-server_linux_amd64/* /opt/teamspeak-server/
    rm -f ~/ts3server.tar.bz*
    rm -rf teamspeak3-server_linux_amd64
    echo "${RELEASE}" >~/.teamspeak-server
    $STD service teamspeak start
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}${IP}:9987${CL}"
