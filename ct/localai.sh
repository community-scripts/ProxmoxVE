#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mudler/LocalAI

APP="localai"
var_tags="${var_tags:-ai;llm;inference;openai-compatible}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
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

  if [[ ! -f /usr/local/bin/local-ai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "localai" "mudler/LocalAI"; then
    msg_info "Stopping Service"
    systemctl stop localai
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "local-ai" "mudler/LocalAI" "singlefile" "latest" "/usr/local/bin" "local-ai-v*-linux-*"

    msg_info "Starting Service"
    systemctl start localai
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
