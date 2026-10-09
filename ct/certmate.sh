#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: fabriziosalmi
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fabriziosalmi/certmate

APP="CertMate"
var_tags="${var_tags:-ssl;certificates;acme}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/certmate ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "certmate" "fabriziosalmi/certmate"; then
    msg_info "Stopping CertMate"
    systemctl stop certmate
    msg_ok "Stopped CertMate"

    PYTHON_VERSION="3.12" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "certmate" "fabriziosalmi/certmate" "tarball"

    msg_info "Installing CertMate Dependencies"
    cd /opt/certmate
    $STD uv venv --python 3.12 /opt/certmate/.venv
    $STD uv pip sync --python /opt/certmate/.venv/bin/python requirements.lock
    $STD /opt/certmate/.venv/bin/certbot --version
    msg_ok "Installed CertMate Dependencies"

    msg_info "Starting CertMate"
    systemctl start certmate
    msg_ok "Started CertMate"
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
echo -e "${INFO}${YW}The first page creates the admin account and asks for the API token: grep API_BEARER_TOKEN /opt/certmate_data/.env${CL}"
