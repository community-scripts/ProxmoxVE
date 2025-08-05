#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.paymenter.org

APP="Paymenter"
var_tags="${var_tags:-hosting;ecommerce;marketplace;}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/paymenter ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT_PHP=$(php -v 2>/dev/null | awk '/^PHP/{print $2}' | cut -d. -f1,2)
  if [[ "$CURRENT_PHP" != "8.3" ]]; then
    PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULE="common,mysql,fpm,redis" setup_php
    setup_composer
    sed -i 's|php8\.2-fpm\.sock|php8.3-fpm.sock|g' /etc/nginx/sites-available/paymenter.conf
    $STD systemctl reload nginx
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/paymenter/paymenter/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f ~/.paymenter ]] || [[ "${RELEASE}" != "$(cat ~/.paymenter)" ]]; then
    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt/paymenter
    $STD php artisan p:upgrade --no-interaction
    echo "${RELEASE}" >~/.paymenter
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
