#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://opencloud.eu

APP="OpenCloud"
var_tags="${var_tags:-files;cloud}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /etc/opencloud ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE="v5.0.2"
  if check_for_gh_release "opencloud" "opencloud-eu/opencloud" "${RELEASE}"; then
    msg_info "Stopping services"
    systemctl stop opencloud opencloud-wopi
    msg_ok "Stopped services"

    msg_info "Updating packages"
    $STD apt-get update
    $STD apt-get dist-upgrade -y
    msg_ok "Updated packages"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "opencloud" "opencloud-eu/opencloud" "singlefile" "${RELEASE}" "/usr/bin" "opencloud-*-linux-amd64"

    msg_info "Starting services"
    systemctl start opencloud opencloud-wopi
    msg_ok "Started services"
    msg_ok "Updated successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://<your-OpenCloud-FQDN>${CL}"
