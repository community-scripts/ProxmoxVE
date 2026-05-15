#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: havardthom | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ollama.com/

APP="Ollama"
var_tags="${var_tags:-ai}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-40}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_gpu="${var_gpu:-yes}"

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
  if check_for_gh_release "ollama" "ollama/ollama"; then
    ensure_dependencies zstd
    msg_info "Stopping Services"
    systemctl stop ollama
    msg_ok "Services Stopped"

    OLLAMA_INSTALL_DIR="/usr/local/lib/ollama"
    rm -rf "$OLLAMA_INSTALL_DIR" /usr/local/bin/ollama
    mkdir -p "$OLLAMA_INSTALL_DIR"
    if ! fetch_and_deploy_gh_release "ollama" "ollama/ollama" "prebuild" "latest" "$OLLAMA_INSTALL_DIR" "ollama-linux-amd64.tar.zst"; then
      msg_error "Download or deployment failed – check network connectivity and GitHub API availability"
      exit 250
    fi
    ln -sf "$OLLAMA_INSTALL_DIR/bin/ollama" /usr/local/bin/ollama
    msg_ok "Updated Ollama"

    msg_info "Starting Services"
    systemctl start ollama
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:11434${CL}"
