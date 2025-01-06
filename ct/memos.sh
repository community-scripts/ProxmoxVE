#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.usememos.com/

# App Default Values
APP="Memos"
var_tags="notes"
var_cpu="2"
var_ram="2048"
var_disk="7"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/memos ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating $APP (Patience)"
  cd /opt/memos
  git reset --hard HEAD
  output=$(git pull --no-rebase)
  if echo "$output" | grep -q "Already up to date."; then
    msg_ok "$APP is already up to date."
    exit
  fi
  systemctl stop memos
  cd /opt/memos/web
  pnpm i --frozen-lockfile &>/dev/null
  pnpm build &>/dev/null
  cd /opt/memos
  mkdir -p /opt/memos/server/dist
  cp -r web/dist/* /opt/memos/server/dist/
  cp -r web/dist/* /opt/memos/server/router/frontend/dist/
  go build -o /opt/memos/memos -tags=embed bin/memos/main.go &>/dev/null
  systemctl start memos
  msg_ok "Updated $APP"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9030${CL}"
