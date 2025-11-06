#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plankanban/planka

APP="PLANKA"
var_tags="${var_tags:-Todo,kanban}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -f /etc/systemd/system/planka.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "planka" "plankanban/planka"; then
    msg_info "Stopping Service"
    systemctl stop planka
    msg_info "Stopped Service"

    msg_info "Backing up data"
    BK="/opt/planka-backup"
    mkdir -p "$BK"/{favicons,user-avatars,background-images,attachments}
    [ -f /opt/planka/.env ] && mv /opt/planka/.env "$BK"/
    [ -d /opt/planka/public/favicons ] && cp -a /opt/planka/public/favicons/. "$BK/favicons/"
    [ -d /opt/planka/public/user-avatars ] && cp -a /opt/planka/public/user-avatars/. "$BK/user-avatars/"
    [ -d /opt/planka/public/background-images ] && cp -a /opt/planka/public/background-images/. "$BK/background-images/"
    [ -d /opt/planka/private/attachments ] && cp -a /opt/planka/private/attachments/. "$BK/attachments/"
    rm -rf /opt/planka
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "planka" "plankanban/planka" "prebuild" "latest" "/opt/planka" "planka-prebuild.zip"

    msg_info "Update Frontend"
    cd /opt/planka
    $STD npm install
    msg_ok "Updated Frontend"

    msg_info "Restoring data"
    [ -f "$BK/.env" ] && mv "$BK/.env" /opt/planka/.env
    mkdir -p /opt/planka/public/{favicons,user-avatars,background-images} /opt/planka/private/attachments
    [ -d "$BK/favicons" ] && cp -a "$BK/favicons/." /opt/planka/public/favicons/
    [ -d "$BK/user-avatars" ] && cp -a "$BK/user-avatars/." /opt/planka/public/user-avatars/
    [ -d "$BK/background-images" ] && cp -a "$BK/background-images/." /opt/planka/public/background-images/
    [ -d "$BK/attachments" ] && cp -a "$BK/attachments/." /opt/planka/private/attachments/
    rm -rf "$BK"
    msg_ok "Restored data"

    msg_info "Starting Service"
    systemctl start planka
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1337${CL}"
