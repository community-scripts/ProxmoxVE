#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: havardthom | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ollama.com/

APP="Ollama"
var_tags="${var_tags:-ai}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-40}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
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
  if [[ ! -d /usr/local/lib/ollama ]]; then
    msg_error "No Ollama Installation Found!"
    exit
  fi

  [[ -f /root/.ollama ]] && rm -f /root/.ollama

  if check_for_gh_release "ollama-com" "ollama/ollama"; then
    ensure_dependencies zstd
    msg_info "Stopping Ollama"
    systemctl stop ollama
    msg_ok "Stopped Ollama"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ollama-com" "ollama/ollama" "prebuild" "latest" "/usr/local/lib/ollama" "ollama-linux-$(arch_resolve).tar.zst"
    if [[ -e /dev/kfd && "$(arch_resolve)" == "amd64" ]]; then
      fetch_and_deploy_gh_release "ollama-rocm-com" "ollama/ollama" "prebuild" "latest" "/usr/local/lib/ollama/lib" "ollama-linux-amd64-rocm.tar.zst"
    fi
    ln -sf /usr/local/lib/ollama/bin/ollama /usr/local/bin/ollama

    msg_info "Starting Ollama"
    systemctl start ollama
    msg_ok "Started Ollama"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:11434${CL}"
