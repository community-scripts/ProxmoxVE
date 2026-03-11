#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ggml-org/llama.cpp

APP="llamacpp"
var_tags="${var_tags:-ai;llm;inference}"
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

  if [[ ! -f /opt/llamacpp/version.txt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "llamacpp" "ggml-org/llama.cpp"; then
    msg_info "Stopping Service"
    systemctl stop llamacpp
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /etc/systemd/system/llamacpp.service /tmp/llamacpp.service.backup
    msg_ok "Backed up Configuration"

    fetch_and_deploy_gh_release "llamacpp" "ggml-org/llama.cpp" "prebuild" "latest" "/opt/llamacpp/bin" "llama-*-bin-ubuntu-vulkan-x64.tar.gz"

    # Create symlinks
    ln -sf /opt/llamacpp/bin/llama-server /usr/local/bin/llama-server 2>/dev/null || true
    ln -sf /opt/llamacpp/bin/llama-cli /usr/local/bin/llama-cli 2>/dev/null || true

    msg_info "Restoring Configuration"
    cp /tmp/llamacpp.service.backup /etc/systemd/system/llamacpp.service
    systemctl daemon-reload
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    systemctl start llamacpp
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW} OpenAI-Compatible API endpoint:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/v1/chat/completions${CL}"
