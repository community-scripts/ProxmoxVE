#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021) | Co-Author: Stavros (steveiliop56)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/steveiliop56/tinyauth

APP="Alpine-Tinyauth"
var_tags="${var_tags:-alpine;auth}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  if [[ ! -d /opt/tinyauth ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating packages"
  $STD apk -U upgrade
  msg_ok "Updated packages"

  RELEASE=$(curl -s https://api.github.com/repos/steveiliop56/tinyauth/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [ "${RELEASE}" != "$(cat ~/.tinyauth 2>/dev/null)" ] || [ ! -f ~/.tinyauth ]; then
    msg_info "Stopping Service"
    $STD service tinyauth stop
    msg_ok "Service Stopped"

    msg_info "Updating Tinyauth"
    rm -f /opt/tinyauth/tinyauth
    curl -fsSL "https://github.com/steveiliop56/tinyauth/releases/download/v${RELEASE}/tinyauth-amd64" -o /opt/tinyauth/tinyauth
    chmod +x /opt/tinyauth/tinyauth
    echo "${RELEASE}" >~/.tinyauth
    msg_ok "Updated Tinyauth"

    msg_info "Restarting Tinyauth"
    $STD service tinyauth start
    msg_ok "Restarted Tinyauth"
    msg_ok "Updated successfully!"
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
