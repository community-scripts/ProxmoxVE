#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.keycloak.org/

APP="Keycloak"
var_tags="${var_tags:-access-management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/keycloak ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "keycloak_app" "keycloak/keycloak"; then
    msg_info "Stopping Service"
    systemctl stop keycloak
    msg_ok "Stopped Service"

    msg_info "Updating packages"
    $STD apt-get update
    $STD apt-get -y upgrade
    msg_ok "Updated packages"

    msg_info "Backup old Keycloak"
    cd /opt
    mv keycloak keycloak.old
    msg_ok "Backup done"

    fetch_and_deploy_gh_release "keycloak_app" "keycloak/keycloak" "prebuild" "latest" "/opt/keycloak" "keycloak-*.tar.gz"

    msg_info "Updating Keycloak"
    cd /opt
    cp -a keycloak.old/conf/. keycloak/conf/
    cp -a keycloak.old/providers/. keycloak/providers/ 2>/dev/null || true
    cp -a keycloak.old/themes/. keycloak/themes/ 2>/dev/null || true
    msg_ok "Updated Keycloak"

    msg_info "Restarting Service"
    systemctl restart keycloak
    msg_ok "Restarted Service"

    msg_info "Cleaning up"
    rm -rf keycloak.old
    msg_ok "Cleanup complete"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/admin${CL}"
