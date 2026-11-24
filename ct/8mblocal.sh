#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/JMS1717/8mb.local

APP="8mbLocal"
var_tags="${var_tags:-media;video;compression}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}" # psutil 5.9.8 (pinned upstream) has no aarch64 wheel and would need a compiler
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

  if [[ ! -d /opt/8mblocal ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "8mblocal" "JMS1717/8mb.local"; then
    msg_info "Stopping 8mb.local"
    systemctl stop 8mblocal 8mblocal-worker
    msg_ok "Stopped 8mb.local"

    NODE_VERSION="22" setup_nodejs
    PYTHON_VERSION="3.12" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "8mblocal" "JMS1717/8mb.local" "tarball"

    msg_info "Building 8mb.local"
    mv /opt/8mblocal /opt/8mblocal-build
    cd /opt/8mblocal-build/frontend
    $STD npm ci
    $STD npm run build
    mkdir -p /opt/8mblocal
    mv /opt/8mblocal-build/backend-api/app /opt/8mblocal/backend
    mv /opt/8mblocal-build/worker/app /opt/8mblocal/worker
    mv /opt/8mblocal-build/shared /opt/8mblocal-build/requirements.txt /opt/8mblocal/
    mv /opt/8mblocal-build/frontend/build /opt/8mblocal/frontend-build
    rm -rf /opt/8mblocal-build
    cd /opt/8mblocal
    $STD uv venv --python 3.12 .venv
    $STD uv pip install --python .venv/bin/python -r requirements.txt packaging
    msg_ok "Built 8mb.local"

    msg_info "Starting 8mb.local"
    systemctl start 8mblocal-worker 8mblocal
    msg_ok "Started 8mb.local"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8001${CL}"
