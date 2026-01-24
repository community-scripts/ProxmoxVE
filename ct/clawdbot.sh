#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: isriam
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clawdbot/clawdbot

# App Default Values
APP="Clawdbot"
var_tags="${var_tags:-ai;assistant}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /etc/systemd/system/clawdbot.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ${APP}"
  $STD npm update -g clawdbot
  msg_ok "Updated ${APP}"

  msg_info "Restarting ${APP}"
  systemctl restart clawdbot
  msg_ok "Restarted ${APP}"

  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access the container and run:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}clawdbot onboard --install-daemon${CL}"
echo -e "${INFO}${YW} This will configure your API keys, channels, and start the daemon.${CL}"
