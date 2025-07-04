#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mafl.hywax.space/

APP="Mafl"
var_tags="${var_tags:-dashboard}"
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
  if [[ ! -d /opt/mafl ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/hywax/mafl/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat ~/.mafl 2>/dev/null)" ]] || [[ ! -f ~/.mafl ]]; then
    msg_info "Stopping Mafl service"
    systemctl stop mafl
    msg_ok "Service stopped"

    msg_info "Performing backup"
    mkdir -p /opt/mafl-backup/data
    mv /opt/mafl/data /opt/mafl-backup/data
    rm /opt/mafl
    msg_ok "Backup complete"
    
    fetch_and_deploy_gh_release "mafl" "hywax/mafl"

    msg_info "Updating Mafl to v${RELEASE}"
    cd /opt/mafl
    yarn install
    yarn build
    systemctl start mafl
    mv /opt/mafl-backup/data /opt/mafl/data
    msg_ok "Updated Mafl to v${RELEASE}"
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
