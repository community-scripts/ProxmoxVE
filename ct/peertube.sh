#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Chocobozzz/PeerTube

APP="PeerTube"
var_tags="${var_tags:-media;video;fediverse}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-40}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_gpu="${var_gpu:-yes}"
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

  if [[ ! -d /opt/peertube ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "peertube" "Chocobozzz/PeerTube"; then
    msg_info "Stopping Service"
    systemctl stop peertube
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "peertube" "Chocobozzz/PeerTube" "prebuild" "latest" "/opt/peertube" "peertube-v*.zip"

    msg_info "Installing Node Dependencies (Patience)"
    cd /opt/peertube
    $STD npm run install-node-dependencies -- --production
    msg_ok "Installed Node Dependencies"

    msg_info "Updating Default Configuration"
    cp /opt/peertube/config/default.yaml /opt/peertube_data/config/default.yaml
    msg_ok "Updated Default Configuration"

    msg_info "Starting Service"
    systemctl start peertube
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
echo -e "${GATEWAY}${BGN}http://${IP}:9000${CL}"
echo -e "${INFO}${YW}The root password was printed to the log on first start:${CL}"
echo -e "${TAB}${DEFAULT}${BGN}journalctl -u peertube | grep -i 'User password'${CL}"
