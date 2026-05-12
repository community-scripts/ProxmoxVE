#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tess1o/geopulse

APP="GeoPulse"
var_tags="${var_tags:-location;tracking;gps}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -f /opt/geopulse/backend/geopulse-backend ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "geopulse-backend" "tess1o/geopulse"; then
    msg_info "Stopping Service"
    systemctl stop geopulse-backend
    msg_ok "Stopped Service"

    if [[ "$(uname -m)" == "aarch64" ]]; then
      if grep -qi "raspberry\|bcm" /proc/cpuinfo 2>/dev/null; then
        BINARY_PATTERN="geopulse-backend-native-arm64-compat-*"
      else
        BINARY_PATTERN="geopulse-backend-native-arm64-[!c]*"
      fi
    else
      if grep -q avx2 /proc/cpuinfo && grep -q bmi2 /proc/cpuinfo && grep -q fma /proc/cpuinfo; then
        BINARY_PATTERN="geopulse-backend-native-amd64-[!c]*"
      else
        BINARY_PATTERN="geopulse-backend-native-amd64-compat-*"
      fi
    fi

    fetch_and_deploy_gh_release "geopulse-backend" "tess1o/geopulse" "singlefile" "latest" "/opt/geopulse/backend" "${BINARY_PATTERN}"
    fetch_and_deploy_gh_release "geopulse-frontend" "tess1o/geopulse" "prebuild" "latest" "/var/www/geopulse" "geopulse-frontend-*.tar.gz"

    msg_info "Starting Service"
    systemctl start geopulse-backend
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
echo -e "${INFO}${YW} To create an admin account, run:${CL}"
echo -e "${TAB}${BGN}/usr/local/bin/create-geopulse-admin${CL}"
