#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/danny-avila/LibreChat

APP="LibreChat"
var_tags="${var_tags:-ai;chat}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/librechat ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_tag "librechat" "danny-avila/LibreChat" "v"; then
    msg_info "Stopping Services"
    systemctl stop librechat rag-api
    msg_ok "Stopped Services"

    create_backup /opt/librechat/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_tag "librechat" "danny-avila/LibreChat"

    msg_info "Installing Dependencies"
    cd /opt/librechat
    $STD npm ci
    msg_ok "Installed Dependencies"

    msg_info "Building Frontend"
    $STD npm run frontend
    $STD npm prune --production
    $STD npm cache clean --force
    msg_ok "Built Frontend"

    restore_backup

    msg_info "Starting Services"
    systemctl start rag-api librechat
    msg_ok "Started Services"
    msg_ok "Updated LibreChat Successfully!"
  fi

  if check_for_gh_release "rag-api" "danny-avila/rag_api"; then
    msg_info "Stopping RAG API"
    systemctl stop rag-api
    msg_ok "Stopped RAG API"

    create_backup /opt/rag-api/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "rag-api" "danny-avila/rag_api" "tarball"

    msg_info "Updating RAG API Dependencies"
    cd /opt/rag-api
    $STD .venv/bin/pip install -r requirements.lite.txt
    msg_ok "Updated RAG API Dependencies"

    restore_backup

    msg_info "Starting RAG API"
    systemctl start rag-api
    msg_ok "Started RAG API"
    msg_ok "Updated RAG API Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3080${CL}"
