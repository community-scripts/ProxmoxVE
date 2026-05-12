#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mattogodoy/nametag

APP="Nametag"
var_tags="${var_tags:-contacts;crm}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/nametag ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "nametag" "mattogodoy/nametag"; then
    msg_info "Stopping Service"
    systemctl stop nametag
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp /opt/nametag/.env /opt/nametag.env.bak
    cp -r /opt/nametag/data /opt/nametag_data_bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "nametag" "mattogodoy/nametag" "tarball" "latest" "/opt/nametag"

    msg_info "Rebuilding Application"
    cd /opt/nametag
    $STD npm ci
    set -a
    source /opt/nametag/.env
    set +a
    $STD npx prisma generate
    $STD npm run build
    cp -r /opt/nametag/.next/static /opt/nametag/.next/standalone/.next/static
    cp -r /opt/nametag/public /opt/nametag/.next/standalone/public
    msg_ok "Rebuilt Application"

    msg_info "Restoring Data"
    cp /opt/nametag.env.bak /opt/nametag/.env
    cp -r /opt/nametag_data_bak/. /opt/nametag/data/
    rm -f /opt/nametag.env.bak
    rm -rf /opt/nametag_data_bak
    msg_ok "Restored Data"

    msg_info "Running Migrations"
    cd /opt/nametag
    $STD npx prisma migrate deploy
    msg_ok "Ran Migrations"

    msg_info "Starting Service"
    systemctl start nametag
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
