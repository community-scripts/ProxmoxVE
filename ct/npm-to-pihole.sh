#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/lazarh/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: lazarh
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CypriotUnknown/npm-to-pihole

APP="NPM-to-PiHole"
var_tags="${var_tags:-dns;networking}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
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

  if [[ ! -f /opt/npm-to-pihole/npm-to-pihole.sh ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ${APP}"
  curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/install/npm-to-pihole-install.sh \
    | bash -s -- --update-only
  msg_ok "Updated ${APP}"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Configure the sync settings:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}nano /opt/npm-to-pihole/config${CL}"
echo -e "${INFO}${YW} Then restart the service:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}systemctl restart npm-to-pihole${CL}"
