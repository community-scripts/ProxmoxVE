#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: reptil1990
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/qdm12/ddns-updater

APP="DDNS-Updater"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/ddns-updater ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "ddns-updater" "qdm12/ddns-updater"; then
    msg_info "Stopping Service"
    systemctl stop ddns-updater
    msg_ok "Stopped Service"

    create_backup /opt/ddns-updater/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ddns-updater" "qdm12/ddns-updater" "singlefile" "latest" "/opt/ddns-updater" "ddns-updater_*_linux_$(arch_resolve)"

    restore_backup

    msg_info "Starting Service"
    systemctl start ddns-updater
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
