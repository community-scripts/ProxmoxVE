#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.paymenter.org | Github: https://github.com/paymenter/paymenter

APP="Paymenter"
var_tags="${var_tags:-hosting;ecommerce;marketplace;}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/paymenter ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  setup_mariadb

  CURRENT_PHP=$(php -v 2>/dev/null | awk '/^PHP/{print $2}' | cut -d. -f1,2)
  if [[ "$CURRENT_PHP" != "8.3" ]]; then
    PHP_VERSION="8.3" PHP_FPM="YES" setup_php
    setup_composer
    PHP_SOCK=$(get_php_fpm_socket)
    sed -i "s|fastcgi_pass unix:.*|fastcgi_pass unix:${PHP_SOCK};|" /etc/nginx/sites-available/paymenter.conf
    nginx_enable_site paymenter.conf
  fi

  if check_for_gh_release "paymenter" "paymenter/paymenter"; then
    msg_info "Updating ${APP}"
    cd /opt/paymenter
    $STD php artisan app:upgrade --no-interaction
    echo "${CHECK_UPDATE_RELEASE}" >~/.paymenter
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
echo -e "${GATEWAY}${BGN}http://${IP}:80${CL}"
