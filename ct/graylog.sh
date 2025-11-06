#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://graylog.org/

APP="Graylog"
var_tags="${var_tags:-logging}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-30}"
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

  if [[ ! -d /etc/graylog ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop graylog-datanode
  systemctl stop graylog-server
  msg_info "Stopped Service"

  CURRENT_VERSION=$(apt list --installed 2>/dev/null | grep graylog-server | grep -oP '\d+\.\d+\.\d+')

  if dpkg --compare-versions "$CURRENT_VERSION" lt "6.3"; then
    MONGO_VERSION="8.0" setup_mongodb

    msg_info "Updating Graylog"
    $STD apt update
    $STD apt upgrade -y
    curl -fsSL "https://packages.graylog2.org/repo/packages/graylog-7.0-repository_latest.deb" -o "graylog-7.0-repository_latest.deb"
    $STD dpkg -i graylog-7.0-repository_latest.deb
    $STD apt update
    $STD apt install -y graylog-server graylog-datanode
    rm -f graylog-7.0-repository_latest.deb
    msg_ok "Updated Graylog"
  elif dpkg --compare-versions "$CURRENT_VERSION" ge "7.0"; then
    msg_info "Updating Graylog"
    $STD apt update
    $STD apt upgrade -y
    msg_ok "Updated Graylog"
  fi

  msg_info "Starting Service"
  systemctl start graylog-datanode
  systemctl start graylog-server
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
