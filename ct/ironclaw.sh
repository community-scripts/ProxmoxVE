#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nearai/ironclaw

APP="IronClaw"
var_tags="${var_tags:-ai;agent;security}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/local/bin/ironclaw ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE="ironclaw-v0.29.1"
  if check_for_gh_release "ironclaw-bin" "nearai/ironclaw" "${RELEASE}" "IronClaw 1.0 (Reborn) is a ground-up rearchitecture with an incompatible CLI/config format; pinned until this script supports it"; then
    msg_info "Stopping Service"
    systemctl stop ironclaw
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /root/.ironclaw/.env /root/ironclaw.env.bak
    msg_ok "Backed up Configuration"

    fetch_and_deploy_gh_release "ironclaw-bin" "nearai/ironclaw" "prebuild" "${RELEASE}" "/usr/local/bin" \
      "ironclaw-$(uname -m)-unknown-linux-gnu.tar.gz"
    chmod +x /usr/local/bin/ironclaw

    msg_info "Restoring Configuration"
    cp /root/ironclaw.env.bak /root/.ironclaw/.env
    rm -f /root/ironclaw.env.bak
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    systemctl start ironclaw
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
echo -e "${INFO}${YW} Next Steps:${CL}"
echo -e "${TAB}1. Configure remaining settings:${CL}"
echo -e "${TAB}${TAB}${BGN}/usr/local/bin/ironclaw onboard${CL}"
echo -e "${TAB}2. Start the service:${CL}"
echo -e "${TAB}${TAB}${BGN}systemctl start ironclaw${CL}"
echo -e "${TAB}3. Access the Web UI at:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo -e "${INFO}${YW} Use Gateway Authentication Token to login:${CL}"
echo -e "${TAB}${TAB}${BGN}cat /root/.ironclaw/gateway.creds${CL}"
