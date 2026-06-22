#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.librenms.org/ | Github: https://github.com/librenms/librenms

APP="LibreNMS"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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
  if [ ! -d /opt/librenms ]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  setup_mariadb
  ensure_dependencies git
  if [[ ! -d /opt/librenms/.git ]]; then
    msg_info "Initializing LibreNMS git metadata"
    LIBRENMS_VERSION=$(cat ~/.librenms 2>/dev/null)
    cd /opt/librenms
    git init -q
    git remote add origin https://github.com/librenms/librenms.git
    git fetch --depth 1 origin "refs/tags/v${LIBRENMS_VERSION}" 2>/dev/null ||
      git fetch --depth 1 origin "refs/tags/${LIBRENMS_VERSION}" 2>/dev/null || true
    git checkout -qf FETCH_HEAD 2>/dev/null || true
    chown -R librenms:librenms .git
    msg_ok "Initialized LibreNMS git metadata"
  fi
  msg_info "Updating LibreNMS"
  $STD su - librenms -s /bin/bash -c 'cd /opt/librenms && ./daily.sh'
  msg_ok "Updated LibreNMS"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
