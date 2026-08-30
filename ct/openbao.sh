#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Marc Went (Dunky13)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openbao.org/

APP="OpenBao"
var_tags="${var_tags:-security;secrets}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -f /usr/bin/bao ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "openbao" "openbao/openbao"; then
    msg_info "Stopping Service"
    systemctl stop openbao
    msg_ok "Stopped Service"

    create_backup /etc/openbao
    DPKG_FORCE_CONFOLD=1 fetch_and_deploy_gh_release "openbao" "openbao/openbao" "binary" "latest" "/opt/openbao" "openbao_*_linux_$(arch_resolve).deb"
    restore_backup

    msg_info "Starting Service"
    $STD systemctl daemon-reload
    systemctl start openbao
    msg_ok "Started Service"
    for _ in {1..15}; do
      BAO_ADDR=https://127.0.0.1:8200 BAO_SKIP_VERIFY=true bao status -format=json 2>/dev/null | jq -e '.sealed == false' >/dev/null && break
      sleep 2
    done
    if ! BAO_ADDR=https://127.0.0.1:8200 BAO_SKIP_VERIFY=true bao status -format=json 2>/dev/null | jq -e '.sealed == false' >/dev/null; then
      msg_error "OpenBao did not unseal within 30 seconds"
      exit 1
    fi
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8200${CL}"
