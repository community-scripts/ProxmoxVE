#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/chroma-core/chroma

APP="Chroma"
var_tags="${var_tags:-database;vector;ai}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -d /opt/chroma ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT=$(cat ~/.chroma)
  RELEASE=$(curl -fsSL https://pypi.org/pypi/chromadb/json | jq -r '.info.version')
  if [[ "$CURRENT" == "$RELEASE" ]]; then
    msg_ok "No update available: Chroma (${CURRENT})"
    exit
  fi

  msg_info "Stopping Chroma"
  systemctl stop chroma
  msg_ok "Stopped Chroma"

  PYTHON_VERSION="3.12" setup_uv

  msg_info "Updating Chroma to ${RELEASE}"
  $STD uv pip install --upgrade --python /opt/chroma/.venv/bin/python "chromadb==${RELEASE}"
  cat <<EOF >~/.chroma
${RELEASE}
EOF
  msg_ok "Updated Chroma to ${RELEASE}"

  msg_info "Starting Chroma"
  systemctl start chroma
  msg_ok "Started Chroma"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000/docs${CL}"
