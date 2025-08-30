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

  if [[ ! -f /etc/systemd/system/planka.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "planka" "plankanban/planka"; then
    msg_info "Stopping $APP"
    systemctl stop planka
    msg_ok "Stopped $APP"

    msg_info "Backing up data"
    mkdir -p /opt/planka-backup/{favicons,user-avatars,background-images,attachments}
    mv /opt/planka/.env /opt/planka-backup
    [ -d /opt/planka/public/favicons ] && find /opt/planka/public/favicons -maxdepth 1 -type f -exec mv -t /opt/planka-backup/favicons {} +
    [ -d /opt/planka/public/user-avatars ] && find /opt/planka/public/user-avatars -maxdepth 1 -type f -exec mv -t /opt/planka-backup/user-avatars {} +
    [ -d /opt/planka/public/background-images ] && find /opt/planka/public/background-images -maxdepth 1 -type f -exec mv -t /opt/planka-backup/background-images {} +
    [ -d /opt/planka/private/attachments ] && find /opt/planka/private/attachments -maxdepth 1 -type f -exec mv -t /opt/planka-backup/attachments {} +
    rm -rf /opt/planka
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "planka" "plankanban/planka" "prebuild" "latest" "/opt/planka" "planka-prebuild.zip"

    msg_info "Update Frontend"
    cd /opt/planka
    $STD npm install
    msg_ok "Updated Frontend"

    msg_info "Restoring data"
    mv /opt/planka-backup/.env /opt/planka/
    [ -d /opt/planka-backup/favicons ] && find /opt/planka-backup/favicons -maxdepth 1 -type f -exec mv -t /opt/planka/public/favicons {} +
    [ -d /opt/planka-backup/user-avatars ] && find /opt/planka-backup/user-avatars -maxdepth 1 -type f -exec mv -t /opt/planka/public/user-avatars {} +
    [ -d /opt/planka-backup/background-images ] && find /opt/planka-backup/background-images -maxdepth 1 -type f -exec mv -t /opt/planka/public/background-images {} +
    [ -d /opt/planka-backup/attachments ] && find /opt/planka-backup/attachments -maxdepth 1 -type f -exec mv -t /opt/planka/private/attachments {} +
    msg_ok "Restored data"

    msg_info "Starting $APP"
    systemctl start planka
    msg_ok "Started $APP"
    msg_ok "Update Successful"
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
