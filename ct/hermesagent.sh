#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
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

  confirm_external_installer "https://hermes-agent.nousresearch.com/" "hermes update (https://hermes-agent.nousresearch.com/)"

  msg_info "Stopping Services"
  systemctl stop hermes-dashboard
  msg_ok "Stopped Services"

  msg_info "Updating Hermes Agent"
  $STD setsid --wait bash -c '
    set -a; source /etc/default/hermes; set +a
    /home/hermes/.local/bin/hermes update --yes
  '
  mapfile -t root_gateway_pids < <(ps -eo user=,pid=,args= | awk '$1 == "root" && /\/home\/hermes\/\.hermes\// && /hermes_cli[.]main/ && / gateway run --replace$/ { print $2 }')
  if ((${#root_gateway_pids[@]})); then
    kill -TERM "${root_gateway_pids[@]}"
    for pid in "${root_gateway_pids[@]}"; do
      while kill -0 "$pid" 2>/dev/null; do
        sleep 0.1
      done
    done
  fi
  if ps -eo user=,args= | awk '$1 == "root" && /\/home\/hermes\/\.hermes\// { found = 1 } END { exit !found }'; then
    msg_warn "A root-owned Hermes process is still running; it may keep writing root-owned files"
  fi
  # A writer racing chown makes files vanish between readdir and chown; one retry covers it.
  if ! chown -R hermes:hermes /home/hermes 2>/dev/null; then
    sleep 1
    chown -R hermes:hermes /home/hermes || msg_warn "Could not take ownership of everything under /home/hermes"
  fi
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
