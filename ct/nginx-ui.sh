#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nginxui.com

APP="Nginx-UI"
var_tags="${var_tags:-webserver;nginx;proxy}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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

  if [[ ! -f /usr/local/bin/nginx-ui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "nginx-ui" "0xJacky/nginx-ui"; then
    msg_info "Stopping Service"
    systemctl stop nginx-ui
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /usr/local/etc/nginx-ui/app.ini /tmp/nginx-ui-app.ini.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "nginx-ui" "0xJacky/nginx-ui" "prebuild" "latest" "/opt/nginx-ui" "nginx-ui-linux-64.tar.gz"

    msg_info "Updating Binary"
    cp /opt/nginx-ui/nginx-ui /usr/local/bin/nginx-ui
    chmod +x /usr/local/bin/nginx-ui
    rm -rf /opt/nginx-ui
    msg_ok "Updated Binary"

    msg_info "Restoring Configuration"
    mv /tmp/nginx-ui-app.ini.bak /usr/local/etc/nginx-ui/app.ini
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    systemctl start nginx-ui
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
