#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://grocy.info/

# App Default Values
APP="grocy"
var_tags="grocery;household"
var_cpu="1"
var_ram="512"
var_disk="2"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/apache2/sites-available/grocy.conf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  php_version=$(php -v | head -n 1 | awk '{print $2}')
  if [[ ! $php_version == "8.3"* ]]; then
    msg_info "Updating PHP"
    curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ bookworm main" >/etc/apt/sources.list.d/php.list
    apt-get update
    apt-get install -y php8.3 php8.3-cli php8.3-{bz2,curl,mbstring,intl,sqlite3,fpm,gd,zip,xml}
    systemctl reload apache2
    apt autoremove
    msg_ok "Updated PHP"
  fi
  msg_info "Updating ${APP}"
  bash /var/www/html/update.sh
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"