#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: JD (pentafive)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clawdbot/clawdbot

APP="Clawdbot"
var_tags="${var_tags:-ai;automation;assistant}"
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
  if [[ ! -f /etc/systemd/system/clawdbot.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(npm show clawdbot version 2>/dev/null)
  CURRENT=$(clawdbot --version 2>/dev/null | head -1 | grep -oP '[\d.]+' || echo "0.0.0")

  if [[ "${RELEASE}" != "${CURRENT}" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"
    $STD npm update -g clawdbot
    systemctl restart clawdbot
    msg_ok "Updated ${APP} to v${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at v${CURRENT}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access the web interface at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3003${CL}"
echo -e "${INFO}${YW} Configuration file:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}/opt/clawdbot/config.yaml${CL}"
echo -e "${INFO}${YW} To configure, edit the config and add your API keys.${CL}"
