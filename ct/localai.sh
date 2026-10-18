#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Bryan Lieberman (BryanCLieberman)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://localai.io

APP="LocalAI"
var_tags="${var_tags:-ai;llm;api}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-30}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_gpu="${var_gpu:-yes}"
var_unprivileged="${var_unprivileged:-1}"

# Values the install script accepts up front
export var_auth="${var_auth:-no}"
export var_api_key="${var_api_key:-}"
export var_port="${var_port:-8080}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/localai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Older installs have no CPU pin; on a host with a GPU but no driver in the
  # container every model then ends in "backend not found".
  if ! grep -q '^LOCALAI_FORCE_META_BACKEND_CAPABILITY=' /opt/localai.env 2>/dev/null &&
    ! ldconfig -p 2>/dev/null | grep -qE 'libcuda[.]so|libamdhip64[.]so|libze_intel_gpu[.]so|libze_loader[.]so'; then
    echo "LOCALAI_FORCE_META_BACKEND_CAPABILITY=default" >>/opt/localai.env
    systemctl restart localai
    msg_ok "Pinned LocalAI to the CPU backends (no GPU runtime in the container)"
  fi

  if check_for_gh_release "localai" "mudler/LocalAI"; then
    msg_info "Stopping Service"
    systemctl stop localai
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "localai" "mudler/LocalAI" "singlefile" "latest" "/opt/localai" "local-ai-v*-linux-$(arch_resolve amd64 arm64)"

    msg_info "Starting Service"
    systemctl start localai
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}Install models from the gallery in the web UI or place GGUF files in /opt/localai_data/models${CL}"
