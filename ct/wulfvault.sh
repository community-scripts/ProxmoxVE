#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2024-2025 community-scripts ORG
# Author: Ulf Holmström (Frimurare)
# License: MIT
# Source: https://github.com/Frimurare/WulfVault

APP="WulfVault"
var_tags="file-sharing;security;gdpr"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="0"

header_info "$APP"
base_settings
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/wulfvault ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP}"
  cd /opt/wulfvault
  docker compose pull
  docker compose up -d
  docker image prune -f
  msg_ok "Updated ${APP}"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable at:"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e ""
echo -e "Default Admin:"
echo -e "${TAB}Email: ${GN}admin@wulfvault.local${CL}"
echo -e "${TAB}Password: ${GN}WulfVaultAdmin2024!${CL}"
echo -e ""
echo -e "${RD}⚠️  Change admin password immediately!${CL}"
