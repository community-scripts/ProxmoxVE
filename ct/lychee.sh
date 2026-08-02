#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/LycheeOrg/Lychee

APP="Lychee"
var_tags="${var_tags:-media;photos;gallery}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/lychee ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "lychee" "LycheeOrg/Lychee"; then
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')

    msg_info "Stopping Services"
    systemctl stop caddy php${PHP_VER}-fpm
    msg_ok "Stopped Services"

    create_backup /opt/lychee/.env \
      /opt/lychee/storage \
      /opt/lychee/public/uploads \
      /opt/lychee/public/dist

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "lychee" "LycheeOrg/Lychee" "prebuild" "latest" "/opt/lychee" "Lychee.zip"

    restore_backup

    msg_info "Updating Application"
    cd /opt/lychee
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan cache:clear
    $STD php artisan optimize:clear
    $STD php artisan optimize
    chown -R www-data:www-data /opt/lychee
    chmod -R 775 /opt/lychee/storage /opt/lychee/bootstrap/cache \
      /opt/lychee/public/dist /opt/lychee/public/uploads
    if [[ "${VERBOSE:-no}" = "yes" ]]; then
      php artisan lychee:diagnostics || true
    fi
    msg_ok "Updated Application"

    msg_info "Starting Services"
    systemctl start caddy php${PHP_VER}-fpm
    msg_ok "Started Services"
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
