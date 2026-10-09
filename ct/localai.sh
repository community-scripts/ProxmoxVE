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
var_gpu="${var_gpu:-yes}"
var_unprivileged="${var_unprivileged:-1}"
# var_arm64 left unset: upstream ships a linux-arm64 asset, but this has never
# been run on an arm64 host, so arch_check asks rather than claiming support.

# Values the install script accepts up front - without the export they never
# reach the container.
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

  if check_for_gh_release "localai" "mudler/LocalAI"; then
    msg_info "Stopping Service"
    systemctl stop localai
    msg_ok "Stopped Service"

    # Models, backends and the env file live outside /opt/localai, so a clean
    # install only ever replaces the binary.
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