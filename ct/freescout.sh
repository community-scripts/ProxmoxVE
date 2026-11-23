#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/freescout-help-desk/freescout

APP="FreeScout"
var_tags="${var_tags:-helpdesk;ticketing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_admin_email="${var_admin_email:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/freescout ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "freescout" "freescout-help-desk/freescout"; then
    msg_info "Stopping FreeScout"
    systemctl stop cron nginx php8.4-fpm
    pkill -u www-data -f artisan || true
    msg_ok "Stopped FreeScout"

    create_backup /opt/freescout/.env
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="storage Modules public/modules" fetch_and_deploy_gh_release "freescout" "freescout-help-desk/freescout" "tarball"
    restore_backup

    msg_info "Updating FreeScout"
    cd /opt/freescout
    $STD php artisan freescout:after-app-update
    $STD php artisan storage:link
    chown -R www-data:www-data /opt/freescout
    msg_ok "Updated FreeScout"

    msg_info "Starting FreeScout"
    systemctl start php8.4-fpm nginx cron
    msg_ok "Started FreeScout"
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
echo -e "${INFO}${YW}Admin credentials: ~/freescout.creds (inside the container)${CL}"
