#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kimai.org/

APP="Kimai"
var_tags="${var_tags:-time-tracking}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-7}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if ! command -v lsb_release; then
    apt install -y lsb-release
  fi
  if [[ ! -d /opt/kimai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  PHP_VERSION="8.4" PHP_MODULE="mysql" PHP_APACHE="YES" setup_php
  setup_composer

    if check_for_gh_release "kimai" "kimai/kimai"; then
    BACKUP_DIR="/opt/kimai_backup"

    msg_info "Stopping Apache2"
    systemctl stop apache2
    msg_ok "Stopped Apache2"

    msg_info "Backing up Kimai configuration and var directory"
    mkdir -p "$BACKUP_DIR"
    [ -d /opt/kimai/var ] && cp -r /opt/kimai/var "$BACKUP_DIR/"
    [ -f /opt/kimai/.env ] && cp /opt/kimai/.env "$BACKUP_DIR/"
    [ -f /opt/kimai/config/packages/local.yaml ] && cp /opt/kimai/config/packages/local.yaml "$BACKUP_DIR/"
    msg_ok "Backup completed"

    fetch_and_deploy_gh_release "kimai" "kimai/kimai"

    msg_info "Updating Kimai"
    [ -d "$BACKUP_DIR/var" ] && cp -r "$BACKUP_DIR/var" /opt/kimai/
    [ -f "$BACKUP_DIR/.env" ] && cp "$BACKUP_DIR/.env" /opt/kimai/
    [ -f "$BACKUP_DIR/local.yaml" ] && cp "$BACKUP_DIR/local.yaml" /opt/kimai/config/packages/
    rm -rf "$BACKUP_DIR"
    cd /opt/kimai
    sed -i '/^admin_lte:/,/^[^[:space:]]/d' config/local.yaml
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
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
