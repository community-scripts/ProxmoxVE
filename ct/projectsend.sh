#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.projectsend.org/

APP="ProjectSend"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /opt/projectsend ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "projectsend" "projectsend/projectsend"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    php_ver=$(php -v | head -n 1 | awk '{print $2}')
    if [[ ! $php_ver == "8.4"* ]]; then
      PHP_VERSION="8.4" PHP_APACHE="YES" PHP_MODULE="pdo,mysql,gettext,fileinfo" setup_php
    fi

    mv /opt/projectsend/includes/sys.config.php /opt/sys.config.php
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "projectsend" "projectsend/projectsend" "prebuild" "latest" "/opt/projectsend" "projectsend-r*.zip"
    mv /opt/sys.config.php /opt/projectsend/includes/sys.config.php
    chown -R www-data:www-data /opt/projectsend
    chmod -R 775 /opt/projectsend

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"

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
