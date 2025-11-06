#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://infisical.com/

APP="Infisical"
var_tags="${var_tags:-auth}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /etc/infisical ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping service"
  $STD infisical-ctl stop
  msg_ok "Service stopped"

  msg_info "Creating backup"
  DB_PASS=$(grep -Po '(?<=^Database Password:\s).*' ~/infisical.creds | head -n1)
  PGPASSWORD=$DB_PASS pg_dump -U infisical -h localhost -d infisical_db > /opt/infisical_backup.sql
  msg_ok "Created backup"

  msg_info "Updating Infisical"
  $STD apt update
  $STD apt install -y infisical-core
  $STD infisical-ctl reconfigure
  msg_ok "Updated Infisical"

  msg_info "Starting service"
  infisical-ctl start
  msg_ok "Started service"
  msg_ok "Updated successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
