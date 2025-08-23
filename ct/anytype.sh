#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jeron Wong (ThisIsJeron)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/anyproto/any-sync-dockercompose

APP="Anytype"
var_tags="${var_tags:-documents}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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
  if [[ ! -d /opt/anytype ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/anyproto/any-sync-dockercompose/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat ~/.anytype 2>/dev/null)" ]] || [[ ! -f ~/.anytype ]]; then
    msg_info "Stopping ${APP}"
    cd /opt/anytype
    make stop >/dev/null 2>&1 || docker compose down >/dev/null 2>&1
    msg_ok "Stopped ${APP}"

    msg_info "Backing up configuration"
    cp /opt/anytype/.env.override /opt/.env.override 2>/dev/null || true
    msg_ok "Configuration backed up"

    msg_info "Updating ${APP} to v${RELEASE}"
    rm -rf /opt/anytype
    git clone --depth 1 --branch "v${RELEASE}" https://github.com/anyproto/any-sync-dockercompose.git /opt/anytype >/dev/null 2>&1
    mv /opt/.env.override /opt/anytype/.env.override 2>/dev/null || true
    cd /opt/anytype
    make start >/dev/null 2>&1 || docker compose up -d >/dev/null 2>&1
    echo "${RELEASE}" > ~/.anytype
    msg_ok "Updated ${APP}"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Configuration file:${CL}"
echo -e "${TAB}${BGN}/opt/anytype/.env.override${CL}"


