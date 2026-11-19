#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/infobyte/faraday

APP="Faraday"
var_tags="${var_tags:-security;vulnerability}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_faraday_password="${var_faraday_password:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/faraday ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "faraday" "infobyte/faraday"; then
    msg_info "Stopping Faraday"
    systemctl stop faraday-beat faraday-worker faraday-server
    msg_ok "Stopped Faraday"

    PYTHON_VERSION="3.11" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "faraday" "infobyte/faraday" "tarball"

    msg_info "Updating Faraday"
    cd /opt/faraday
    UV_PROJECT_ENVIRONMENT=/opt/faraday/venv $STD uv sync --frozen --no-dev --no-editable
    FARADAY_HOME=/opt/faraday_data $STD venv/bin/faraday-manage migrate
    msg_ok "Updated Faraday"

    msg_info "Starting Faraday"
    systemctl start faraday-server faraday-worker faraday-beat
    msg_ok "Started Faraday"
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
echo -e "${GATEWAY}${BGN}http://${IP}:5985${CL}"
