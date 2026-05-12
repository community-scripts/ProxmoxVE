#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://checkmk.com/

APP="checkmk"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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
  if ! command -v omd &>/dev/null; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl_with_retry "https://api.github.com/repos/checkmk/checkmk/tags" "-" | grep "name" | awk '{print substr($2, 3, length($2)-4) }' | tr ' ' '\n' | grep -Ev 'rc|b' | sort -V | tail -n 1)
  RELEASE="${RELEASE%%+*}"
  msg_info "Updating checkmk"
  $STD omd stop monitoring
  $STD omd cp monitoring monitoringbackup
  curl_with_retry "https://download.checkmk.com/checkmk/${RELEASE}/check-mk-community-${RELEASE}_0.$(get_os_info codename)_amd64.deb" "/opt/checkmk.deb"
  $STD apt install -y /opt/checkmk.deb
  $STD omd --force -V ${RELEASE}.cre update --conflict=install monitoring
  $STD omd start monitoring
  $STD omd -f rm monitoringbackup
  $STD omd cleanup
  rm -rf /opt/checkmk.deb
  msg_ok "Updated checkmk"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/monitoring${CL}"
