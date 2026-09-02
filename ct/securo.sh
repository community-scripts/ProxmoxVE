#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/securo-finance/securo

APP="Securo"
var_tags="${var_tags:-finance;self-hosted}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/securo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "securo" "securo-finance/securo"; then
    msg_info "Stopping Services"
    systemctl stop securo securo-worker securo-beat
    msg_ok "Stopped Services"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "securo" "securo-finance/securo" "tarball"

    msg_info "Updating Backend"
    cd /opt/securo/backend
    ln -sf /opt/securo_data/.env /opt/securo/backend/.env
    $STD uv venv --python 3.12 /opt/securo/backend/.venv
    $STD uv pip install --python /opt/securo/backend/.venv -e .
    set -a
    source /opt/securo_data/.env
    set +a
    $STD /opt/securo/backend/.venv/bin/alembic upgrade head
    msg_ok "Updated Backend"

    msg_info "Rebuilding Frontend"
    cd /opt/securo/frontend
    export NODE_OPTIONS="--max-old-space-size=4096"
    $STD npm install
    $STD npm run build
    msg_ok "Rebuilt Frontend"

    msg_info "Starting Services"
    systemctl start securo securo-worker securo-beat
    systemctl reload nginx
    msg_ok "Started Services"
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
echo -e "${GATEWAY}${BGN}https://${IP}${CL}"
