#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: DragoQC | Co-Author: nickheyer
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://discopanel.app/ | Github: https://github.com/nickheyer/discopanel

APP="DiscoPanel"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
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

  if [[ ! -d "/opt/discopanel" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  setup_docker

  if check_for_gh_release "discopanel" "nickheyer/discopanel"; then
    msg_info "Stopping Service"
    systemctl stop discopanel
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    mkdir -p /opt/discopanel_backup_temp
    cp /opt/discopanel/data/discopanel.db /opt/discopanel_backup_temp/discopanel.db
    msg_ok "Created Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "discopanel" "nickheyer/discopanel" "prebuild" "latest" "/opt/discopanel" "discopanel-linux-amd64.tar.gz"
    ln -sf /opt/discopanel/discopanel-linux-amd64 /opt/discopanel/discopanel

    msg_info "Restoring Data"
    mkdir -p /opt/discopanel/data
    mv /opt/discopanel_backup_temp/discopanel.db /opt/discopanel/data/discopanel.db
    rm -rf /opt/discopanel_backup_temp
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start discopanel
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
