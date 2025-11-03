#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://grocy.info/

APP="grocy"
var_tags="${var_tags:-grocery;household}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -f /etc/apache2/sites-available/grocy.conf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  php_ver=$(php -v | head -n 1 | awk '{print $2}')
  if [[ ! $php_ver == "8.3"* ]]; then
    PHP_VERSION="8.3" PHP_MODULE="sqlite3,bz2" PHP_APACHE="yes" setup_php
  fi
  if check_for_gh_release "grocy" "grocy/grocy"; then
    msg_info "Updating ${APP}"
    bash /var/www/html/update.sh
    msg_ok "Updated successfully!"
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
