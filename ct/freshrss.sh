#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FreshRSS/FreshRSS

APP="FreshRSS"
var_tags="${var_tags:-RSS}"
var_cpu="${var_cpu:-2}"
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
  if [[ ! -d /opt/freshrss ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [ ! -x /opt/freshrss/cli/sensitive-log.sh ]; then
    msg_info "Fixing wrong permissions"
    chmod +x /opt/freshrss/cli/sensitive-log.sh
    systemctl restart apache2
    msg_ok "Fixed wrong permissions"
    exit
  else
    msg_error "FreshRSS should be updated via the user interface."
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
