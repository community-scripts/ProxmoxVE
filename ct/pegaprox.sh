#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PegaProx/project-pegaprox

APP="PegaProx"
var_tags="${var_tags:-proxmox;management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/pegaprox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pegaprox" "PegaProx/project-pegaprox"; then
    msg_info "Stopping Service"
    systemctl stop pegaprox
    msg_ok "Stopped Service"

    create_backup /opt/pegaprox/config /etc/pegaprox/secret.key

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pegaprox" "PegaProx/project-pegaprox" "tarball"

    msg_info "Updating Python Environment"
    $STD uv venv --python 3.12 /opt/pegaprox/venv
    $STD uv pip install --python /opt/pegaprox/venv/bin/python -r /opt/pegaprox/requirements.txt
    msg_ok "Updated Python Environment"

    restore_backup

    msg_info "Starting Service"
    systemctl start pegaprox
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:5000${CL}"
