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

  RELEASE=$(curl -fsSL https://api.github.com/repos/oauth2-proxy/oauth2-proxy/releases/latest | jq -r .tag_name | sed 's/^v//')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP} services"
    systemctl stop oauth2-proxy
    msg_ok "Stopped ${APP}"

    msg_info "Updating $APP to ${RELEASE}"
    rm -f /opt/oauth2-proxy/oauth2-proxy
    curl -fsSL "https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v${RELEASE}/oauth2-proxy-v${RELEASE}.linux-amd64.tar.gz" -o /opt/oauth2-proxy.tar.gz
    tar -xzf /opt/oauth2-proxy.tar.gz
    mv /opt/oauth2-proxy-v${RELEASE}.linux-amd64/oauth2-proxy /opt/oauth2-proxy
    systemctl start oauth2-proxy
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Cleaning up"
    rm -f "/opt/oauth2-proxy.tar.gz"
    rm -rf "/opt/oauth2-proxy-v${RELEASE}.linux-amd64"
    $STD apt-get -y autoremove
    $STD apt-get -y autoclean
    msg_ok "Cleaned"
  else
    msg_ok "${APP} is already up to date (${RELEASE})"
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Now you can modify /opt/oauth2-proxy/config.toml with your needed config.${CL}"
