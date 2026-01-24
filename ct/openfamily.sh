#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: NexaFlowFrance
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NexaFlowFrance/OpenFamily

APP="OpenFamily"
var_tags="${var_tags:-family;productivity;organization}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  
  if [[ ! -d /opt/openfamily ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  NODE_VERSION="20" NODE_MODULE="pnpm@latest" setup_nodejs
  
  msg_info "Updating ${APP}"
  cd /opt/openfamily
  
  RELEASE=$(curl -fsSL https://api.github.com/repos/NexaFlowFrance/OpenFamily/releases/latest | \
    grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
  
  if [[ ! -f /opt/openfamily_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/openfamily_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"
    systemctl stop openfamily
    
    $STD git fetch origin
    $STD git checkout "v${RELEASE}"
    
    cd /opt/openfamily/client
    $STD pnpm install
    $STD pnpm build
    
    cd /opt/openfamily/server
    $STD pnpm install
    
    echo "${RELEASE}" >/opt/openfamily_version.txt
    systemctl start openfamily
    
    msg_ok "Updated ${APP} to v${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
