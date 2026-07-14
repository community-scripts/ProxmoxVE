#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://heimdall.site/ | Github: https://github.com/linuxserver/Heimdall

APP="Heimdall-Dashboard"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -d /opt/Heimdall ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "Heimdall" "linuxserver/Heimdall"; then
    msg_info "Stopping Service"
    systemctl stop heimdall
    sleep 1
    msg_ok "Stopped Service"

    create_backup /opt/Heimdall/database \
                  /opt/Heimdall/public
    PHP_VERSION="8.4" PHP_FPM="YES" setup_php
    setup_composer
    fetch_and_deploy_gh_release "Heimdall" "linuxserver/Heimdall" "tarball"
    restore_backup

    msg_info "Updating Heimdall-Dashboard"
    cd /opt/Heimdall
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer dump-autoload
    msg_ok "Updated Heimdall-Dashboard"

    msg_info "Starting Service"
    systemctl start heimdall.service
    sleep 2
    msg_ok "Started Service"
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
echo -e "${GATEWAY}${BGN}http://${IP}:7990${CL}"
