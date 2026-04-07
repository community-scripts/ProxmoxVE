#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: piotrlaczykowski
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/vllm-project/vllm

APP="vLLM"
var_tags="${var_tags:-ai;llm}"
var_cpu="${var_cpu:-8}"
var_ram="${var_ram:-16384}"
var_disk="${var_disk:-40}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-0}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/vllm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/vllm-project/vllm/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
  if [[ ! -f /opt/vLLM_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/vLLM_version.txt)" ]]; then
    if [[ ! -f /opt/vLLM_version.txt ]]; then
      touch /opt/vLLM_version.txt
    fi

    msg_info "Stopping Service"
    systemctl stop vllm
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to ${RELEASE}"
    source /opt/vllm/bin/activate
    $STD pip install --upgrade "vllm==${RELEASE#v}"
    echo "${RELEASE}" >/opt/vLLM_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting Service"
    systemctl start vllm
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW} OpenAI-compatible API endpoint:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000/v1${CL}"
echo -e "${INFO}${YW} Swagger docs:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000/docs${CL}"
