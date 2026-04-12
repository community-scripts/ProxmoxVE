#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/papra-hq/papra

APP="Papra"
var_tags="${var_tags:-document-management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/papra ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "papra" "papra-hq/papra"; then
    msg_info "Stopping Service"
    systemctl stop papra
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    if [[ -f /opt/papra/apps/papra-server/.env ]]; then
      cp /opt/papra/apps/papra-server/.env /opt/papra_env.bak
    fi
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "papra" "papra-hq/papra" "tarball"

    msg_info "Building Application"
    cd /opt/papra
    if [[ -f /opt/papra_env.bak ]]; then
      cp /opt/papra_env.bak /opt/papra/apps/papra-server/.env
    else
      msg_warn ".env missing, regenerating from defaults"
      LOCAL_IP=$(hostname -I | awk '{print $1}')
      cat <<EOF >/opt/papra/apps/papra-server/.env
NODE_ENV=production
SERVER_SERVE_PUBLIC_DIR=true
PORT=1221
DATABASE_URL=file:/opt/papra_data/db/db.sqlite
DOCUMENT_STORAGE_FILESYSTEM_ROOT=/opt/papra_data/documents
PAPRA_CONFIG_DIR=/opt/papra_data
AUTH_SECRET=$(cat /opt/papra_data/.secret)
BETTER_AUTH_SECRET=$(cat /opt/papra_data/.secret)
BETTER_AUTH_TELEMETRY=0
CLIENT_BASE_URL=http://${LOCAL_IP}:1221
SERVER_BASE_URL=http://${LOCAL_IP}:1221
EMAILS_DRY_RUN=true
INGESTION_FOLDER_IS_ENABLED=true
INGESTION_FOLDER_ROOT_PATH=/opt/papra_data/ingestion
EOF
    fi
    $STD pnpm install --frozen-lockfile
    $STD pnpm --filter "@papra/app-client..." run build
    $STD pnpm --filter "@papra/app-server..." run build
    ln -sf /opt/papra/apps/papra-client/dist /opt/papra/apps/papra-server/public
    rm -f /opt/papra_env.bak
    msg_ok "Built Application"

    msg_info "Starting Service"
    systemctl start papra
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1221${CL}"
