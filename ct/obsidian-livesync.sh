#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/vrtmrz/obsidian-livesync | https://couchdb.apache.org/

APP="Obsidian-LiveSync"
var_tags="${var_tags:-documents;notes}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/couchdb/etc/local.d/obsidian-livesync.ini ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping CouchDB"
  systemctl stop couchdb
  msg_ok "Stopped CouchDB"

  create_backup /var/lib/couchdb /opt/couchdb/etc/local.d/obsidian-livesync.ini /opt/obsidian-livesync/.env

  msg_info "Updating Container OS"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated Container OS"

  systemctl stop couchdb
  restore_backup

  msg_info "Starting CouchDB"
  systemctl start couchdb
  msg_ok "Started CouchDB"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Configure the Self-hosted LiveSync plugin with the credentials in /opt/obsidian-livesync/.env${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5984/_utils/${CL}"
