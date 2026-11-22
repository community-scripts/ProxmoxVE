#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mathesar-foundation/mathesar

APP="Mathesar"
var_tags="${var_tags:-database;postgresql;spreadsheet}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/mathesar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "mathesar" "mathesar-foundation/mathesar"; then
    msg_info "Stopping Mathesar"
    systemctl stop mathesar
    msg_ok "Stopped Mathesar"

    PYTHON_VERSION="3.12" setup_uv
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="sso.yml file_storage.yml login_page.yml" fetch_and_deploy_gh_release "mathesar" "mathesar-foundation/mathesar" "prebuild" "latest" "/opt/mathesar" "mathesar.tar.gz"

    msg_info "Updating Mathesar"
    cd /opt/mathesar
    $STD uv venv --python 3.12 /opt/mathesar/.venv
    $STD uv pip install --python /opt/mathesar/.venv/bin/python -r requirements.txt
    set -a
    source /opt/mathesar_data/.env
    set +a
    $STD /opt/mathesar/.venv/bin/python -m mathesar.install
    msg_ok "Updated Mathesar"

    msg_info "Starting Mathesar"
    systemctl start mathesar
    msg_ok "Started Mathesar"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
