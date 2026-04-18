#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Patrick Veverka
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plastic-labs/honcho

APP="Honcho"
var_tags="${var_tags:-ai;memory}"
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

  if [[ ! -d /opt/honcho ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "honcho" "plastic-labs/honcho"; then
    PYTHON_VERSION="3.12" setup_uv

    msg_info "Stopping Services"
    systemctl stop honcho-api honcho-deriver
    msg_ok "Stopped Services"

    msg_info "Backing up Configuration"
    cp -f /opt/honcho/.env /opt/honcho.env.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "honcho" "plastic-labs/honcho" "tarball"

    msg_info "Installing Python Dependencies"
    cd /opt/honcho
    $STD uv sync
    msg_ok "Installed Python Dependencies"

    msg_info "Restoring Configuration"
    mv -f /opt/honcho.env.bak /opt/honcho/.env
    msg_ok "Restored Configuration"

    msg_info "Running Database Migrations"
    $STD uv run alembic upgrade head
    msg_ok "Ran Database Migrations"

    msg_info "Starting Services"
    systemctl start honcho-api honcho-deriver
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW} Configure your LLM provider in:${CL}"
echo -e "${TAB}${BGN}/opt/honcho/.env${CL}"
