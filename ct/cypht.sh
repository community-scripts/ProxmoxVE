#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cypht-org/cypht

APP="Cypht"
var_tags="${var_tags:-email;webmail}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_admin_user="${var_admin_user:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/cypht ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "cypht" "cypht-org/cypht"; then
    msg_info "Stopping Cypht"
    systemctl stop nginx php8.4-fpm
    msg_ok "Stopped Cypht"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cypht" "cypht-org/cypht" "prebuild" "latest" "/opt/cypht" "cypht.tar.gz"

    msg_info "Updating Cypht"
    ln -sf /opt/cypht_data/.env /opt/cypht/.env
    cd /opt/cypht
    $STD php scripts/setup_database.php
    $STD php scripts/config_gen.php
    chown -R www-data:www-data /opt/cypht_data/users /opt/cypht_data/attachments
    msg_ok "Updated Cypht"

    msg_info "Starting Cypht"
    systemctl start php8.4-fpm nginx
    msg_ok "Started Cypht"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}Login: /opt/cypht_data/.env (inside the container)${CL}"
