#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/juanfont/headscale

APP="Headscale"
var_tags="${var_tags:-tailscale}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -d /etc/headscale ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ -f /opt/${APP}_version.txt ]]; then
    mv /opt/"${APP}_version.txt" ~/.headscale
  fi

  if check_for_gh_release "headscale" "juanfont/headscale"; then
    msg_info "Stopping Service"
    systemctl stop headscale
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "headscale" "juanfont/headscale" "binary"
    fetch_and_deploy_gh_release "headscale-admin" "GoodiesHQ/headscale-admin" "prebuild" "latest" "/opt/headscale-admin" "admin.zip"

    msg_info "Starting Service"
    systemctl enable -q --now headscale
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
echo -e "${TAB}${GATEWAY}${BGN}Headscale API: ${IP}/api (no Frontend) | headscale-admin: http://${IP}/admin/${CL}"
