#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lklynet/aurral

APP="Aurral"
var_tags="${var_tags:-music;lidarr;discovery}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/aurral ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "aurral" "lklynet/aurral"; then
    msg_info "Stopping Service"
    systemctl stop aurral
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "aurral" "lklynet/aurral" "tarball"
    NODE_VERSION="22" setup_nodejs

    msg_info "Updating Aurral"
    cd /opt/aurral
    export VITE_APP_VERSION="$(cat ~/.aurral)"
    export VITE_GITHUB_REPO="lklynet/aurral"
    export VITE_RELEASE_CHANNEL="stable"
    $STD npm ci --workspace frontend --include-workspace-root=false
    $STD npm run build --workspace frontend
    $STD npm ci --workspace backend --omit=dev --include=optional --include-workspace-root=false
    mkdir -p /opt/aurral_data
    cat <<EOF >/opt/aurral/aurral.env
NODE_ENV=production
PORT=3001
AURRAL_DATA_DIR=/opt/aurral_data
APP_VERSION=$(cat ~/.aurral)
EOF
    msg_ok "Updated Aurral"

    msg_info "Starting Service"
    systemctl start aurral
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
echo -e "${GATEWAY}${BGN}http://${IP}:3001${CL}"
