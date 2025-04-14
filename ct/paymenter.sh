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
    msg_info "Migrating PHP $CURRENT_PHP to 8.3"
    $STD curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
    $STD dpkg -i /tmp/debsuryorg-archive-keyring.deb
    $STD sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
    $STD apt-get update
    $STD apt-get remove -y php"${CURRENT_PHP//./}"*
    $STD apt-get install -y \
      php8.3 \
      php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,curl,zip,intl,redis,fpm}
    sed -i 's|php8\.2-fpm\.sock|php8.3-fpm.sock|g' /etc/nginx/sites-available/paymenter.conf
    $STD systemctl reload nginx
    msg_ok "Migrated PHP $CURRENT_PHP to 8.3"
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/paymenter/paymenter/releases/latest | grep '"tag_name"' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating ${APP} to ${RELEASE}"
    echo "${RELEASE}" >/opt/${APP}_version.txt
    cd /opt/paymenter || exit
    $STD php artisan p:upgrade --no-interaction
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
