#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stephen Chin (steveonjava)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://hermes-agent.nousresearch.com/

APP="Hermes Agent"
var_tags="${var_tags:-ai;automation;agent}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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

  if [[ ! -x /home/hermes/.local/bin/hermes ]]; then
    msg_error "No Hermes Agent Installation Found!"
    exit
  fi

  msg_warn "WARNING: This script will run an external installer from a third-party source (https://hermes-agent.nousresearch.com/)."
  msg_warn "The following code is NOT maintained or audited by our repository."
  msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
  msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  hermes update (https://hermes-agent.nousresearch.com/)"
  echo
  read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
  if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    msg_error "Aborted by user. No changes have been made."
    exit 10
  fi

  msg_info "Stopping Services"
  systemctl stop hermes-dashboard
  msg_ok "Stopped Services"

  msg_info "Updating Hermes Agent"
  $STD setsid --wait bash -c '
    set -a; source /etc/default/hermes; set +a
    /home/hermes/.local/bin/hermes update --yes
  '
  chown -R hermes:hermes /home/hermes
  msg_ok "Updated Hermes Agent"

  msg_info "Starting Services"
  systemctl start hermes-dashboard
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}Hermes Agent setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Configure your model provider and gateway server inside the container:${CL}"
echo -e "${TAB}${BGN}hermes-setup${CL}"
echo -e "${INFO} When prompted to install the gateway service, choose 'user service'.${CL}"
echo -e "${INFO}${YW} Key for Hermes API Server stored in:${CL}"
echo -e "${TAB}${BGN}/home/hermes/.hermes/.env${CL}"
