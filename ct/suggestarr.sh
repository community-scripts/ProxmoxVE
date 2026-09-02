#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/giuseppe99barchetta/SuggestArr

APP="SuggestArr"
var_tags="${var_tags:-arr;media}"
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

  if [[ ! -d /opt/suggestarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "suggestarr" "giuseppe99barchetta/SuggestArr"; then
    msg_info "Stopping Service"
    systemctl stop suggestarr
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "suggestarr" "giuseppe99barchetta/SuggestArr" "tarball"

    msg_info "Building Frontend"
    cd /opt/suggestarr/client
    $STD npm install
    $STD npm run build
    mkdir -p /opt/suggestarr/static
    cp -r /opt/suggestarr/client/dist/* /opt/suggestarr/static/
    cp -r /opt/suggestarr/client/node_modules/swagger-ui-dist /opt/suggestarr/static/swagger-ui
    msg_ok "Built Frontend"

    msg_info "Updating Python Environment"
    cd /opt/suggestarr
    $STD uv venv --python 3.12 /opt/suggestarr/.venv
    $STD uv pip install --python /opt/suggestarr/.venv -r /opt/suggestarr/api_service/requirements.txt
    msg_ok "Updated Python Environment"

    msg_info "Starting Service"
    systemctl start suggestarr
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5000${CL}"
