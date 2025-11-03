#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.qbittorrent.org/

APP="qBittorrent"
var_tags="${var_tags:-torrent}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/qbittorrent-nox.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ ! -f ~/.qbittorrent ]]; then
    msg_error "Please create new qBittorrent LXC. Updating from v4.x to v5.x is not supported!"
    exit
  fi
  if check_for_gh_release "qbittorrent" "userdocs/qbittorrent-nox-static"; then
    msg_info "Stopping Service"
    systemctl stop qbittorrent-nox
    msg_ok "Stopped Service"

    rm -f /opt/qbittorrent/qbittorrent-nox
    fetch_and_deploy_gh_release "qbittorrent" "userdocs/qbittorrent-nox-static" "singlefile" "latest" "/opt/qbittorrent" "x86_64-qbittorrent-nox"
    mv /opt/qbittorrent/qbittorrent /opt/qbittorrent/qbittorrent-nox

    msg_info "Starting Service"
    systemctl start qbittorrent-nox
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8090${CL}"
