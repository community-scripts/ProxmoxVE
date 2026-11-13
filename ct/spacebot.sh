#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/spacedriveapp/spacebot

APP="Spacebot"
var_tags="${var_tags:-ai;agent;chatops}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_llm_base_url="${var_llm_base_url:-}"
export var_llm_api_key="${var_llm_api_key:-}"
export var_llm_model="${var_llm_model:-}"

if [[ -n "$var_llm_base_url" && -z "$var_llm_model" ]]; then
  msg_error "var_llm_model is required with var_llm_base_url."
  exit 1
fi

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/spacebot ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "spacebot" "spacedriveapp/spacebot"; then
    msg_info "Stopping Spacebot"
    systemctl stop spacebot
    msg_ok "Stopped Spacebot"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "spacebot" "spacedriveapp/spacebot" "prebuild" "latest" "/opt/spacebot" "spacebot-v*-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.tar.gz"

    msg_info "Starting Spacebot"
    systemctl start spacebot
    msg_ok "Started Spacebot"
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
echo -e "${GATEWAY}${BGN}http://${IP}:19898${CL}"
