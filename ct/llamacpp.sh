#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: Heretek-AI
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ggml-org/llama.cpp

APP="llama.cpp"
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

  if [[ ! -f /etc/systemd/system/llamacpp.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  # Get latest release from GitHub
  LATEST_RELEASE=$(curl -fsSL https://api.github.com/repos/ggml-org/llama.cpp/releases/latest 2>/dev/null | grep "tag_name" | awk -F'"' '{print $4}')
  
  if [[ -z "$LATEST_RELEASE" ]]; then
    msg_error "Could not fetch latest release version"
    exit 1
  fi

  CURRENT_VERSION=""
  if [[ -f /opt/llamacpp/version.txt ]]; then
    CURRENT_VERSION=$(cat /opt/llamacpp/version.txt)
  fi

  if [[ "$LATEST_RELEASE" != "$CURRENT_VERSION" ]]; then
    msg_info "Stopping llama.cpp Server"
    systemctl stop llamacpp
    msg_ok "Stopped llama.cpp Server"

    msg_info "Backing up configuration"
    cp /etc/systemd/system/llamacpp.service /tmp/llamacpp.service.backup 2>/dev/null || true
    msg_ok "Backed up configuration"

    msg_info "Updating llama.cpp to ${LATEST_RELEASE}"

    TMP_TAR=$(mktemp --suffix=.tar.gz)
    DOWNLOAD_URL="https://github.com/ggml-org/llama.cpp/releases/download/${LATEST_RELEASE}/llama-${LATEST_RELEASE}-bin-ubuntu-vulkan-x64.tar.gz"
    curl -fL# -C - -o "${TMP_TAR}" "${DOWNLOAD_URL}"
    
    rm -rf /opt/llamacpp/bin
    mkdir -p /opt/llamacpp/bin
    tar -xzf "${TMP_TAR}" -C /opt/llamacpp/bin --strip-components=1
    rm -f "${TMP_TAR}"
    
    # Create symlinks
    ln -sf /opt/llamacpp/bin/llama-server /usr/local/bin/llama-server 2>/dev/null || true
    ln -sf /opt/llamacpp/bin/llama-cli /usr/local/bin/llama-cli 2>/dev/null || true
    
    echo "${LATEST_RELEASE}" > /opt/llamacpp/version.txt
    msg_ok "Updated llama.cpp to ${LATEST_RELEASE}"

    msg_info "Restoring configuration"
    cp /tmp/llamacpp.service.backup /etc/systemd/system/llamacpp.service 2>/dev/null || true
    systemctl daemon-reload
    msg_ok "Restored configuration"

    msg_info "Starting llama.cpp Server"
    systemctl start llamacpp
    msg_ok "Started llama.cpp Server"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. llama.cpp is already at ${LATEST_RELEASE}"
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
