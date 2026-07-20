#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://matomo.org/

APP="Matomo"
var_tags="${var_tags:-analytics;tracking;privacy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/matomo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "matomo" "matomo-org/matomo"; then
    msg_info "Stopping Services"
    systemctl stop caddy
    msg_ok "Stopped Services"

    create_backup /opt/matomo/config/config.ini.php /opt/matomo/misc/user /root/matomo.creds

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "matomo" "matomo-org/matomo" "prebuild" "latest" "/opt/matomo" "matomo-*.zip"

    msg_info "Setting up Matomo"
    if [[ -d /opt/matomo/matomo ]]; then
      rm -rf /opt/matomo/tmp "/opt/matomo/How to install Matomo.html"
      find /opt/matomo/matomo -mindepth 1 -maxdepth 1 -exec mv -t /opt/matomo {} +
      rm -rf /opt/matomo/matomo
    fi
    mkdir -p /opt/matomo/tmp
    chmod -R 755 /opt/matomo/tmp
    msg_ok "Set up Matomo"

    restore_backup
    chown -R www-data:www-data /opt/matomo

    if [[ -f /opt/matomo/console ]]; then
      msg_info "Running Matomo database upgrade"
      cd /opt/matomo
      $STD runuser -u www-data -- php console core:update --no-interaction
      msg_ok "Ran Matomo database upgrade"
    fi

    msg_info "Starting Services"
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
    systemctl restart "php${PHP_VER}-fpm"
    systemctl start caddy
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
