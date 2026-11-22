#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tim Moore (angusmaul)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TheWicklowWolf/Lidify

APP="Lidify"
var_tags="${var_tags:-arr;music}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/lidify ]]; then
    msg_error "No Lidify Installation Found!"
    exit
  fi

  if check_for_gh_release "lidify" "TheWicklowWolf/Lidify"; then
    msg_info "Stopping Lidify"
    systemctl stop lidify
    msg_ok "Stopped Lidify"

    PYTHON_VERSION="3.12" setup_uv
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="config" fetch_and_deploy_gh_release "lidify" "TheWicklowWolf/Lidify" "tarball"

    msg_info "Updating Lidify"
    $STD uv venv --python 3.12 /opt/lidify/.venv
    $STD uv pip install --python /opt/lidify/.venv/bin/python -r /opt/lidify/requirements.txt
    cat <<EOF >/opt/lidify/.env
RELEASE_VERSION=$(cat ~/.lidify)
EOF
    msg_ok "Updated Lidify"

    msg_info "Starting Lidify"
    systemctl start lidify
    msg_ok "Started Lidify"
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
