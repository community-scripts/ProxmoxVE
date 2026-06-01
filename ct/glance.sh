#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/glanceapp/glance

APP="Glance"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/systemd/system/glance.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "glance" "glanceapp/glance"; then
    msg_info "Stopping Service"
    systemctl stop glance
    msg_ok "Stopped Service"

    if [[ -f /opt/glance/glance.yml ]]; then
      msg_info "Backing up glance.yml"
      cp /opt/glance/glance.yml /tmp/glance.yml.bak
      msg_ok "Backed up glance.yml"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "glance" "glanceapp/glance" "prebuild" "latest" "/opt/glance" "glance-linux-amd64.tar.gz"

    if [[ -f /tmp/glance.yml.bak ]]; then
      msg_info "Restoring glance.yml"
      mv /tmp/glance.yml.bak /opt/glance/glance.yml
      msg_ok "Restored glance.yml"
    fi

    msg_info "Starting Service"
    systemctl start glance
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
