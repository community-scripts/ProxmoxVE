#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://ztnet.network

APP="ZTNet"
var_tags="${var_tags:-network;vpn;zerotier}"
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

  if [[ ! -d /opt/ztnet ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ztnet" "sinamics/ztnet"; then
    msg_info "Stopping Service"
    systemctl stop ztnet
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/ztnet/data /opt/ztnet_data_backup 2>/dev/null || true
    cp /opt/ztnet/.env /opt/ztnet_env_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ztnet" "sinamics/ztnet" "tarball" "latest" "/opt/ztnet"

    msg_info "Installing Dependencies"
    cd /opt/ztnet || exit
    export NODE_OPTIONS=--dns-result-order=ipv4first
    $STD npm install
    msg_ok "Installed Dependencies"

    msg_info "Running Database Migrations"
    export DATABASE_URL=$(grep DATABASE_URL /opt/ztnet_env_backup | cut -d'=' -f2-)
    $STD npx prisma migrate deploy
    $STD npx prisma db seed
    msg_ok "Database Migrations Complete"

    msg_info "Building Application"
    $STD npm run build
    msg_ok "Built Application"

    msg_info "Restoring Data"
    cp -r /opt/ztnet_data_backup/. /opt/ztnet/data 2>/dev/null || true
    cp /opt/ztnet_env_backup /opt/ztnet/.env 2>/dev/null || true
    rm -rf /opt/ztnet_data_backup /opt/ztnet_env_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start ztnet
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
