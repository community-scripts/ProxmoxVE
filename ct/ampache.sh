#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ampache/ampache

APP="Ampache"
var_tags="${var_tags:-music}"
var_disk="${var_disk:-5}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/ampache ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "Ampache" "ampache/ampache"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    create_backup /opt/ampache/config/ampache.cfg.php \
      /opt/ampache/public/rest/.htaccess \
      /opt/ampache/public/play/.htaccess \
      /opt/ampache/advanced-config

    if ! dpkg -l 2>/dev/null | grep -q "libapache2-mod-php8.5"; then
      PHP_VERSION="8.5" PHP_APACHE="YES" setup_php
      sed -i -e 's/upload_max_filesize = .*/upload_max_filesize = 100M/' \
        -e 's/post_max_size = .*/post_max_size = 100M/' \
        -e 's/max_execution_time = .*/max_execution_time = 600/' \
        -e 's/memory_limit = .*/memory_limit = 512M/' /etc/php/8.5/apache2/php.ini
    fi

    fetch_and_deploy_gh_release "Ampache" "ampache/ampache" "prebuild" "latest" "/opt/ampache" "ampache-*_all_php8.5.zip"

    restore_backup
    chmod 664 /opt/ampache/public/rest/.htaccess /opt/ampache/public/play/.htaccess
    chown -R www-data:www-data /opt/ampache

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
    msg_custom "⚠️" "${YW}" "Complete database update by visiting: http://${LOCAL_IP}/update.php"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}/install.php${CL}"
