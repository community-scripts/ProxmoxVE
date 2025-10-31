#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: kkroboth
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fileflows.com/

APP="FileFlows"
var_tags="${var_tags:-media;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/fileflows ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! [[ $(dpkg -s jq 2>/dev/null) ]]; then
    $STD apt-get update
    $STD apt-get install -y jq
  fi

  update_available=$(curl -fsSL -X 'GET' "http://localhost:19200/api/status/update-available" -H 'accept: application/json' | jq .UpdateAvailable)
  if [[ "${update_available}" == "true" ]]; then
    msg_info "Stopping Service"
    systemctl stop fileflows
    msg_info "Stopped Service"

    msg_info "Creating Backup"
    backup_filename="/opt/${APP}_backup_$(date +%F).tar.gz"
    tar -czf "$backup_filename" -C /opt/fileflows Data
    msg_ok "Backup Created"

    msg_info "Updating $APP to latest version"
    temp_file=$(mktemp)
    curl -fsSL https://fileflows.com/downloads/zip -o "$temp_file"
    $STD unzip -o -d /opt/fileflows "$temp_file"
    msg_ok "Updated $APP to latest version"

    msg_info "Starting Service"
    systemctl start fileflows
    msg_ok "Started Service"

    msg_info "Cleaning Up"
    rm -rf "$temp_file"
    rm -rf "$backup_filename"
    msg_ok "Cleanup Completed"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at latest version"
  fi

  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:19200${CL}"
