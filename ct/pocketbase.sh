#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pocketbase.io/ | Repo: https://ganigeorgiev.com/pocketbase/pocketbase

APP="Pocketbase"
var_tags="${var_tags:-database}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/pocketbase.service || ! -x /opt/pocketbase/pocketbase ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL "https://ganigeorgiev.com/api/collections/releases/records?filter=channel.repository.name%3D%22pocketbase%22%20%26%26%20channel.name%3D%22default%22&sort=-semver&skipTotal=1&perPage=1" | jq -r '.items[0].tag' | sed 's/^v//')
  if [[ -n "$RELEASE" && "$RELEASE" != "$(cat ~/.pocketbase 2>/dev/null)" ]]; then
    msg_info "Stopping Service"
    systemctl stop pocketbase
    msg_ok "Stopped Service"

    fetch_and_deploy_from_url "https://ganigeorgiev.com/meta/pocketbase/pocketbase/download/v${RELEASE}/pocketbase_${RELEASE}_linux_$(arch_resolve).zip" "/opt/pocketbase"
    echo "${RELEASE}" >~/.pocketbase

    msg_info "Starting Service"
    systemctl start pocketbase
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080/_/${CL}"
