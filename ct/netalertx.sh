#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/netalertx/NetAlertX

APP="NetAlertX"
var_tags="${var_tags:-network;monitoring}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/netalertx ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "netalertx" "netalertx/NetAlertX"; then
    msg_info "Stopping NetAlertX"
    systemctl stop netalertx
    msg_ok "Stopped NetAlertX"

    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP=".venv" fetch_and_deploy_gh_release "netalertx" "netalertx/NetAlertX" "tarball"

    msg_info "Updating NetAlertX"
    cd /opt/netalertx
    $STD uv pip install --python .venv/bin/python -r requirements.txt
    ln -sfn /opt/netalertx/install/production-filesystem/services /opt/netalertx/services
    echo "v$(cat ~/.netalertx)" >/opt/netalertx/.VERSION
    date +%s >/opt/netalertx/front/buildtimestamp.txt
    msg_ok "Updated NetAlertX"

    msg_info "Starting NetAlertX"
    systemctl start netalertx
    msg_ok "Started NetAlertX"
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
echo -e "${GATEWAY}${BGN}http://${IP}:20211${CL}"
echo -e "${INFO}${YW}The login password is in /opt/netalertx_data/.env${CL}"
