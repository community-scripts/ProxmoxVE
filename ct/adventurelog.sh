#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://adventurelog.app/

APP="AdventureLog"
var_tags="${var_tags:-traveling}"
var_disk="${var_disk:-7}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/adventurelog ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! command -v memcached >/dev/null 2>&1; then
    $STD apt update
    $STD apt install -y memcached libmemcached-tools
  fi
  if check_for_gh_release "adventurelog" "seanmorley15/adventurelog"; then
    msg_info "Stopping Services"
    systemctl stop adventurelog-backend
    systemctl stop adventurelog-frontend
    msg_ok "Services Stopped"

    msg_info "Backup Old Installation"
    cp -r /opt/adventurelog /opt/adventurelog-backup
    rm -rf /opt/adventurelog
    msg_ok "Backup done"

    fetch_and_deploy_gh_release "adventurelog" "seanmorley15/adventurelog"
    PYTHON_VERSION="3.13" setup_uv

    msg_info "Updating ${APP}"
    cp /opt/adventurelog-backup/backend/server/.env /opt/adventurelog/backend/server/.env
    cp -r /opt/adventurelog-backup/backend/server/media /opt/adventurelog/backend/server/media
    cd /opt/adventurelog/backend/server || exit
    if [[ ! -x .venv/bin/python ]]; then
      $STD uv venv .venv
      $STD .venv/bin/python -m ensurepip --upgrade
    fi
    $STD .venv/bin/python -m pip install --upgrade pip
    $STD .venv/bin/python -m pip install -r requirements.txt
    $STD .venv/bin/python -m manage collectstatic --noinput
    $STD .venv/bin/python -m manage migrate

    cp /opt/adventurelog-backup/frontend/.env /opt/adventurelog/frontend/.env
    cd /opt/adventurelog/frontend || exit
    $STD pnpm i
    $STD pnpm build
    msg_ok "Updated ${APP}"

    msg_info "Starting Services"
    systemctl daemon-reexec
    systemctl start adventurelog-backend
    systemctl start adventurelog-frontend
    msg_ok "Services Started"

    msg_info "Cleaning Up"
    rm -rf /opt/adventurelog-backup
    msg_ok "Cleaned"
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
