#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nearai/ironclaw

APP="Alpine-IronClaw"
var_tags="${var_tags:-ai;agent;alpine}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info

  if [[ ! -f /usr/local/bin/ironclaw ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ironclaw-bin" "nearai/ironclaw"; then
    msg_info "Stopping Service"
    rc-service ironclaw stop 2>/dev/null || true
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /root/.ironclaw/.env /root/ironclaw.env.bak
    msg_ok "Backed up Configuration"

    fetch_and_deploy_gh_release "ironclaw-bin" "nearai/ironclaw" "prebuild" "latest" "/usr/local/bin" \
      "ironclaw-$(uname -m)-unknown-linux-musl.tar.gz"
    chmod +x /usr/local/bin/ironclaw

    msg_info "Restoring Configuration"
    cp /root/ironclaw.env.bak /root/.ironclaw/.env
    rm -f /root/ironclaw.env.bak
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    rc-service ironclaw start
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
echo -e "${INFO}${YW} Complete setup by running:${CL}"
echo -e "${TAB}${BGN}ironclaw onboard${CL}"
echo -e "${INFO}${YW} Then start the service:${CL}"
echo -e "${TAB}${BGN}rc-service ironclaw start${CL}"
echo -e "${INFO}${YW} Access the Web UI at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo -e "${INFO}${YW} Auth token and database credentials:${CL}"
echo -e "${TAB}${BGN}cat /root/.ironclaw/.env${CL}"
