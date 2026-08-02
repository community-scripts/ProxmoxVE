#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: fstof
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/donetick/donetick

APP="Donetick"
var_tags="${var_tags:-productivity;tasks}"
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

  if [[ ! -d /opt/donetick ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "donetick" "donetick/donetick"; then
    msg_info "Stopping Service"
    systemctl stop donetick
    msg_ok "Stopped Service"

    create_backup /opt/donetick/config/selfhosted.yaml \
      /opt/donetick/donetick.db

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "donetick" "donetick/donetick" "prebuild" "latest" "/opt/donetick" "donetick_Linux_$(arch_resolve "x86_64" "arm64").tar.gz"

    restore_backup
    grep -q 'http://localhost"$' /opt/donetick/config/selfhosted.yaml || sed -i '/https:\/\/localhost"$/a\    - "http://localhost"' /opt/donetick/config/selfhosted.yaml
    grep -q 'capacitor://localhost' /opt/donetick/config/selfhosted.yaml || sed -i '/http:\/\/localhost"$/a\    - "capacitor://localhost"' /opt/donetick/config/selfhosted.yaml

    msg_info "Starting Service"
    systemctl start donetick
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
echo -e "${GATEWAY}${BGN}http://${IP}:2021${CL}"
