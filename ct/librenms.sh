#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.librenms.org/ | Github: https://github.com/librenms/librenms

APP="LibreNMS"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/librenms ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "librenms" "librenms/librenms"; then
    msg_info "Stopping Services"
    systemctl stop php8.4-fpm librenms-scheduler.timer
    msg_ok "Stopped Services"

    create_backup /opt/librenms/.env /opt/librenms/config.php /opt/librenms/rrd
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "librenms" "librenms/librenms" "tarball"
    restore_backup

    msg_info "Updating LibreNMS"
    mkdir -p /opt/librenms/{rrd,logs,bootstrap/cache,storage}
    chown -R librenms:librenms /opt/librenms
    chmod 771 /opt/librenms
    chmod -R ug=rwX /opt/librenms/bootstrap/cache /opt/librenms/storage /opt/librenms/logs /opt/librenms/rrd
    $STD su - librenms -s /bin/bash -c "cd /opt/librenms && uv venv --clear .venv && source .venv/bin/activate && uv pip install -r requirements.txt"
    $STD su - librenms -s /bin/bash -c "cd /opt/librenms && COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev"
    $STD su - librenms -s /bin/bash -c "cd /opt/librenms && php8.4 artisan optimize:clear"
    $STD su - librenms -s /bin/bash -c "cd /opt/librenms && php8.4 artisan migrate --force --isolated"
    msg_ok "Updated LibreNMS"

    msg_info "Starting Services"
    systemctl start php8.4-fpm librenms-scheduler.timer
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
