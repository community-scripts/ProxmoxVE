#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/arp242/goatcounter

APP="GoatCounter"
var_tags="${var_tags:-analytics;privacy}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_admin_email="${var_admin_email:-}"
export var_admin_pass="${var_admin_pass:-}"
export var_goatcounter_domain="${var_goatcounter_domain:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/goatcounter/goatcounter ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "goatcounter" "arp242/goatcounter"; then
    msg_info "Stopping GoatCounter"
    systemctl stop goatcounter
    msg_ok "Stopped GoatCounter"

    fetch_and_deploy_gh_release "goatcounter" "arp242/goatcounter" "singlefile" "latest" "/opt/goatcounter" "goatcounter-v*-linux-$(arch_resolve).gz"
    mv /opt/goatcounter/goatcounter /opt/goatcounter/goatcounter.gz
    gunzip -f /opt/goatcounter/goatcounter.gz

    msg_info "Starting GoatCounter"
    systemctl start goatcounter
    msg_ok "Started GoatCounter"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}Admin login: /opt/goatcounter_data/.env (inside the container)${CL}"
