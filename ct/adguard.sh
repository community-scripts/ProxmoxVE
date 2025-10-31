#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://adguard.com/

APP="Adguard"
var_tags="${var_tags:-adblock}"
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
  if [[ ! -d /opt/AdGuardHome ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "AdGuardHome" "AdguardTeam/AdGuardHome"; then
    read -r -p "It is recommended to update AdGuard Home from the web interface. Would you like to continue with a manual update? <y/N> " prompt
    if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
      msg_info "Installing AdGuard Home to temporary location"
      fetch_and_deploy_gh_release "AdGuardHome" "AdguardTeam/AdGuardHome" "prebuild" "latest" "/opt/AdGuardHome.temp" "AdGuardHome_linux_amd64.tar.gz"
      msg_ok "Installed AdGuard Home to temporary location"

      msg_info "Stopping Service"
      systemctl stop AdGuardHome
      msg_ok "Stopped Service"

      msg_info "Backing up Configuration"
      cp /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome.yaml
      cp -r /opt/AdGuardHome/data /opt/AdGuardHome_data
      msg_ok "Backed up Configuration"

      msg_info "Moving new AdGuard Home to correct location"
      rm -rf /opt/AdGuardHome
      mv /opt/AdGuardHome.temp /opt/AdGuardHome
      msg_ok "Moved new AdGuard Home to correct location"

      msg_info "Restoring Configuration"
      mv /opt/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml
      rm -rf /opt/AdGuardHome/data
      mv /opt/AdGuardHome_data /opt/AdGuardHome/data
      msg_ok "Restored Configuration"
      
      msg_info "Starting Service"
      systemctl start AdGuardHome
      msg_ok "Started Service"
    fi
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
