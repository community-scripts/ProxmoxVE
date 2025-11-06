#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: lucasfell
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghostfol.io/

APP="Ghostfolio"
var_tags="${var_tags:-finance;investment}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /opt/ghostfolio/dist/apps/api/main.js ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ghostfolio" "ghostfolio/ghostfolio"; then
    msg_info "Stopping Service"
    systemctl stop ghostfolio
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    tar -czf "/opt/ghostfolio_backup_$(date +%F).tar.gz" \
      -C /opt \
      --exclude="ghostfolio/node_modules" \
      --exclude="ghostfolio/dist" \
      ghostfolio
    mv /opt/ghostfolio/.env /opt/env.backup
    msg_ok "Backup Created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ghostfolio" "ghostfolio/ghostfolio" "tarball" "latest" "/opt/ghostfolio"

    msg_info "Updating Ghostfolio"
    mv /opt/env.backup /opt/ghostfolio/.env
    cd /opt/ghostfolio
    $STD npm ci
    $STD npm run build:production
    $STD npx prisma migrate deploy
    msg_ok "Updated Ghostfolio"

    msg_info "Starting Service"
    systemctl start ghostfolio
    msg_ok "Started Service"

    msg_info "Cleaning Up"
    $STD npm cache clean --force
    msg_ok "Cleanup Completed"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3333${CL}"
