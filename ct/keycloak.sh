#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.keycloak.org/

# App Default Values
APP="Keycloak"
var_tags="access-management"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/keycloak.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} LXC"

  msg_info "Updating packages"
  apt-get update &>/dev/null
  apt-get -y upgrade &>/dev/null

  RELEASE=$(curl -s https://api.github.com/repos/keycloak/keycloak/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  msg_info "Updating Keycloak to v$RELEASE"
  cd /opt
  wget -q https://github.com/keycloak/keycloak/releases/download/$RELEASE/keycloak-$RELEASE.tar.gz
  mv keycloak keycloak.old
  tar -xzf keycloak-$RELEASE.tar.gz
  cp -r keycloak.old/conf keycloak-$RELEASE
  cp -r keycloak.old/providers keycloak-$RELEASE
  cp -r keycloak.old/themes keycloak-$RELEASE
  mv keycloak-$RELEASE keycloak

  msg_info "Delete temporary installation files"
  rm keycloak-$RELEASE.tar.gz
  rm -rf keycloak.old

  msg_info "Restating Keycloak"
  systemctl restart keycloak
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/admin${CL}"
