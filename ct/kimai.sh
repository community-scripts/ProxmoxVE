#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kimai.org/ | Github: https://github.com/kimai/kimai

APP="Kimai"
var_tags="${var_tags:-time-tracking}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-7}"
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
  ensure_dependencies lsb-release
  if [[ ! -d /opt/kimai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  setup_mariadb

  PHP_VERSION="8.4" PHP_APACHE="YES" setup_php
  setup_composer

  if check_for_gh_release "kimai" "kimai/kimai"; then
    BACKUP_DIR="/opt/kimai_backup"

    msg_info "Stopping Apache2"
    systemctl stop apache2
    msg_ok "Stopped Apache2"

    create_backup /opt/kimai/var \
      /opt/kimai/.env \
      /opt/kimai/config/packages/local.yaml
    fetch_and_deploy_gh_release "kimai" "kimai/kimai" "tarball"
    restore_backup

    msg_info "Updating Kimai"
    if grep -q "^APP_SECRET=$" /opt/kimai/.env; then
      APP_SECRET=$(openssl rand -hex 48)
      sed -i "s|^APP_SECRET=.*|APP_SECRET=${APP_SECRET}|" /opt/kimai/.env
    fi

    cd /opt/kimai
    sed -i '/^admin_lte:/,/^[^[:space:]]/d' config/packages/local.yaml
    $STD composer install --no-dev --optimize-autoloader
    $STD bin/console kimai:update
    msg_ok "Updated Kimai"

    msg_info "Starting Apache2"
    systemctl start apache2
    msg_ok "Started Apache2"

    msg_info "Setup Permissions"
    chown -R :www-data /opt/*
    chmod -R g+r /opt/*
    chmod -R g+rw /opt/*
    chown -R www-data:www-data /opt/*
    chmod -R 777 /opt/*
    rm -rf "$BACKUP_DIR"
    msg_ok "Setup Permissions"
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
