#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/marimo-team/marimo

APP="marimo"
var_tags="${var_tags:-notebook;python;data}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_token_password="${var_token_password:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/marimo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "marimo" "marimo-team/marimo"; then
    msg_info "Stopping marimo"
    systemctl stop marimo
    msg_ok "Stopped marimo"

    PYTHON_VERSION="3.13" setup_uv

    msg_info "Updating marimo"
    $STD uv pip install --upgrade --python /opt/marimo/.venv/bin/python "marimo[recommended]==${CHECK_UPDATE_RELEASE}" pandas
    cat <<EOF >~/.marimo
${CHECK_UPDATE_RELEASE}
EOF
    msg_ok "Updated marimo"

    msg_info "Starting marimo"
    systemctl start marimo
    msg_ok "Started marimo"
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
echo -e "${GATEWAY}${BGN}http://${IP}:2718${CL}"
echo -e "${INFO}${YW}Password: MARIMO_TOKEN_PASSWORD in /opt/marimo_data/.env (inside the container)${CL}"
