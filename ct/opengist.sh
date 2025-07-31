#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jonathan (jd-apprentice)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://opengist.io/

APP="Opengist"
var_tags="${var_tags:-development}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /opt/opengist ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/thomiceli/opengist/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f ~/.opengist ]] || [[ "${RELEASE}" != "$(cat ~/.opengist)" ]]; then
    msg_info "Stopping Service"
    systemctl stop opengist
    msg_ok "Stopped Service"

    msg_info "Creating backup"
    mv /opt/opengist /opt/opengist-backup
    msg_ok "Backup created"
    
    fetch_and_deploy_gh_release "opengist" "thomiceli/opengist" "prebuild" "latest" "/opt/opengist" "opengist*linux-amd64.tar.gz"

    msg_info "Configuring ${APP}"
    mv /opt/opengist-backup/config.yml /opt/opengist/config.yml
    msg_ok "Configured ${APP}"

    msg_info "Starting Service"
    systemctl start opengist
    msg_ok "Started Service"

    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6157${CL}"
