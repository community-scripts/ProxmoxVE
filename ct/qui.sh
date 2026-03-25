#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/autobrr/qui

APP="Qui"
var_tags="${var_tags:-torrent}"
var_disk="${var_disk:-10}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -f /usr/local/bin/qui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "Qui" "autobrr/qui"; then
    msg_info "Stopping Service"
    systemctl stop qui
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "qui" "autobrr/qui" "prebuild" "latest" "/tmp/qui" "qui_*_linux_x86_64.tar.gz"

    msg_info "Updating qui"
    mv /tmp/qui/qui /usr/local/bin/qui
    chmod +x /usr/local/bin/qui
    rm -rf /tmp/qui
    msg_ok "Updated qui"

    msg_info "Starting Service"
    systemctl start qui
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7476${CL}"
