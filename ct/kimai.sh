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
var_version="${var_version:-12}"
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
  CURRENT_PHP=$(php -v 2>/dev/null | awk '/^PHP/{print $2}' | cut -d. -f1,2)
  if [[ "$CURRENT_PHP" != "8.4" ]]; then
    msg_info "Migrating PHP $CURRENT_PHP to 8.4"
    $STD curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
    $STD dpkg -i /tmp/debsuryorg-archive-keyring.deb
    $STD sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
    $STD apt-get update
    $STD apt-get remove -y php"${CURRENT_PHP//./}"*
    $STD apt-get install -y \
      php8.4 composer \
      php8.4-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl,fpm} \
      libapache2-mod-php8.4
    msg_ok "Migrated PHP $CURRENT_PHP to 8.4"
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/kimai/kimai/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  BACKUP_DIR="/opt/kimai_backup"

  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Apache2"
    systemctl stop apache2
    msg_ok "Stopped Apache2"

    msg_info "Backing up Kimai configuration and var directory"
    mkdir -p "$BACKUP_DIR"
    [ -d /opt/kimai/var ] && cp -r /opt/kimai/var "$BACKUP_DIR/"
    [ -f /opt/kimai/.env ] && cp /opt/kimai/.env "$BACKUP_DIR/"
    [ -f /opt/kimai/config/packages/local.yaml ] && cp /opt/kimai/config/packages/local.yaml "$BACKUP_DIR/"
    msg_ok "Backup completed"

    msg_info "Updating ${APP} to ${RELEASE}"
    trap "echo Unable to download release file for version ${RELEASE}; try again later" ERR
    set -e
    curl -fsSL "https://github.com/kimai/kimai/archive/refs/tags/${RELEASE}.zip" -o $(basename "https://github.com/kimai/kimai/archive/refs/tags/${RELEASE}.zip")
    $STD unzip "${RELEASE}".zip
    set +e
    trap - ERR
    rm -rf /opt/kimai
    mv kimai-"${RELEASE}" /opt/kimai
    [ -d "$BACKUP_DIR/var" ] && cp -r "$BACKUP_DIR/var" /opt/kimai/
    [ -f "$BACKUP_DIR/.env" ] && cp "$BACKUP_DIR/.env" /opt/kimai/
    [ -f "$BACKUP_DIR/local.yaml" ] && cp "$BACKUP_DIR/local.yaml" /opt/kimai/config/packages/
    rm -rf "$BACKUP_DIR"
    cd /opt/kimai
    $STD composer install --no-dev --optimize-autoloader
    $STD bin/console kimai:update
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting Apache2"
    systemctl start apache2
    msg_ok "Started Apache2"

    msg_info "Setup Permissions"
    chown -R :www-data /opt/*
    chmod -R g+r /opt/*
    chmod -R g+rw /opt/*
    chown -R www-data:www-data /opt/*
    chmod -R 777 /opt/*
    msg_ok "Setup Permissions"

    msg_info "Cleaning Up"
    rm -rf "${RELEASE}".zip
    rm -rf "$BACKUP_DIR"
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
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
