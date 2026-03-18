#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: Heretek-AI
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/unslothai/unsloth

APP="unsolth-studio"
var_tags="${var_tags:-ai;llm;fine-tuning;training}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-16384}"
var_disk="${var_disk:-50}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/unsolth-studio ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if command -v unsloth &>/dev/null; then
    CURRENT_VERSION=$(pip show unsloth 2>/dev/null | grep -i version | awk '{print $2}' || echo "unknown")
    msg_info "Current version: ${CURRENT_VERSION}"
    
    msg_info "Checking for updates"
    $STD pip install --upgrade unsloth 2>/dev/null
    
    NEW_VERSION=$(pip show unsloth 2>/dev/null | grep -i version | awk '{print $2}' || echo "unknown")
    
    if [[ "$CURRENT_VERSION" != "$NEW_VERSION" ]]; then
      msg_ok "Updated from ${CURRENT_VERSION} to ${NEW_VERSION}"
    else
      msg_ok "Already at latest version: ${NEW_VERSION}"
    fi
  else
    msg_error "Unsloth not installed properly"
    exit 1
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8888${CL}"
echo -e "${INFO}${YW} Note: First launch may take 5-10 minutes to compile llama.cpp${CL}"
