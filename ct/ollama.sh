#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: havardthom | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ollama.com/

APP="Ollama"
var_tags="${var_tags:-ai}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-35}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /usr/local/lib/ollama ]]; then
    msg_error "No Ollama Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/ollama/ollama/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
  if [[ ! -f /opt/Ollama_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/Ollama_version.txt)" ]]; then
    if [[ ! -f /opt/Ollama_version.txt ]]; then
      touch /opt/Ollama_version.txt
    fi
    msg_info "Stopping Services"
    systemctl stop ollama
    msg_ok "Services Stopped"

    TMP_TAR=$(mktemp --suffix=.tgz)
    curl -fL# -C - -o "${TMP_TAR}" "https://github.com/ollama/ollama/releases/download/${RELEASE}/ollama-linux-amd64.tgz"
    msg_info "Updating Ollama to ${RELEASE}"
    rm -rf /usr/local/lib/ollama
    rm -rf /usr/local/bin/ollama
    mkdir -p /usr/local/lib/ollama
    tar -xzf "${TMP_TAR}" -C /usr/local/lib/ollama
    ln -sf /usr/local/lib/ollama/bin/ollama /usr/local/bin/ollama
    echo "${RELEASE}" >/opt/Ollama_version.txt
    msg_ok "Updated Ollama to ${RELEASE}"

    msg_info "Starting Services"
    systemctl start ollama
    msg_ok "Started Services"

    msg_info "Cleaning Up"
    rm -f "${TMP_TAR}"
    msg_ok "Cleaned"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. Ollama is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:11434${CL}"
