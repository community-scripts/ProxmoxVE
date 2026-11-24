#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/typecho/typecho

APP="Typecho"
var_tags="${var_tags:-blog;cms}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_admin_user="${var_admin_user:-admin}"
export var_admin_pass="${var_admin_pass:-$(random_password)}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/typecho ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "typecho" "typecho/typecho"; then
    msg_info "Stopping Typecho"
    systemctl stop nginx
    msg_ok "Stopped Typecho"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "typecho" "typecho/typecho" "prebuild" "latest" "/opt/typecho" "typecho.zip"
    fetch_and_deploy_from_url "https://github.com/typecho/languages/releases/download/ci/langs.zip" "/opt/typecho_data/usr/langs"

    msg_info "Linking Typecho Data"
    rm -rf /opt/typecho/usr /opt/typecho/install.php
    ln -s /opt/typecho_data/usr /opt/typecho/usr
    ln -s /opt/typecho_data/config.inc.php /opt/typecho/config.inc.php
    msg_ok "Linked Typecho Data"

    msg_info "Starting Typecho"
    systemctl start nginx
    msg_ok "Started Typecho"
    msg_ok "Updated successfully!"
    echo -e "${INFO}${YW}Open http://${LOCAL_IP}/admin/ and confirm the database upgrade if Typecho asks for one${CL}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}Admin panel: http://${IP}/admin/${CL}"
echo -e "${INFO}${YW}Admin Username: ${var_admin_user}${CL}"
echo -e "${INFO}${YW}Admin Password: ${var_admin_pass}${CL}"
