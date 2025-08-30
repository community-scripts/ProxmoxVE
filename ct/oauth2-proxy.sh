#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/oauth2-proxy/oauth2-proxy/

APP="oauth2-proxy"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-3}"
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

  if [[ ! -d /opt/oauth2-proxy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "oauth2-proxy" "oauth2-proxy/oauth2-proxy"; then
    msg_info "Stopping Service"
    systemctl stop oauth2-proxy
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "oauth2-proxy" "oauth2-proxy/oauth2-proxy" "prebuild" "latest" "/opt/oauth2-proxy" "oauth2-proxy*linux-amd64.tar.gz"

    msg_info "Starting Service"
    systemctl start oauth2-proxy
    msg_ok "Started Service"
    msg_ok "Updated successfully!\n"
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Now you can modify /opt/oauth2-proxy/config.toml with your needed config.${CL}"
