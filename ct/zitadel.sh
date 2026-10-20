#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: dave-yap (dave-yap)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zitadel.com/ | Github: https://github.com/zitadel/zitadel

APP="Zitadel"
var_tags="${var_tags:-identity-provider}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

if [[ -z "${var_zitadel_login:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_zitadel_login=$(msg_menu "Choose the Zitadel login UI" \
    "v2" "Login V2 (Zitadel's default for new instances)" \
    "v1" "Login V1 (classic login built into the API)")
fi
export var_zitadel_login="${var_zitadel_login:-v2}"

header_info "$APP"
variables
color
catch_errors

if [[ ! "${var_zitadel_login}" =~ ^v[12]$ ]]; then
  msg_error "var_zitadel_login must be v1 or v2"
  exit 1
fi

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/zitadel.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "zitadel" "zitadel/zitadel"; then
    msg_info "Stopping Zitadel"
    if [[ -f /etc/systemd/system/zitadel-login.service ]]; then
      systemctl stop zitadel-login
    fi
    systemctl stop zitadel
    msg_ok "Stopped Zitadel"

    fetch_and_deploy_gh_release "zitadel" "zitadel/zitadel" "prebuild" "${CHECK_UPDATE_RELEASE}" "/usr/local/bin" "zitadel-linux-$(arch_resolve).tar.gz"
    if [[ -f /etc/systemd/system/zitadel-login.service ]]; then
      NODE_VERSION="24" setup_nodejs
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "zitadel-login" "zitadel/zitadel" "prebuild" "${CHECK_UPDATE_RELEASE}" "/opt/zitadel-login" "zitadel-login.tar.gz"
    fi

    msg_info "Migrating Zitadel Database"
    $STD zitadel setup --masterkeyFile /opt/zitadel/.masterkey --config /opt/zitadel/config.yaml --init-projections=true
    msg_ok "Migrated Zitadel Database"

    msg_info "Starting Zitadel"
    systemctl start zitadel
    if [[ -f /etc/systemd/system/zitadel-login.service ]]; then
      systemctl start zitadel-login
    fi
    msg_ok "Started Zitadel"
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
if [[ "${var_zitadel_login}" == "v1" ]]; then
  echo -e "${GATEWAY}${BGN}http://${IP}:8080/ui/console${CL}"
else
  echo -e "${GATEWAY}${BGN}https://${IP}:8080/ui/console${CL}"
fi
echo -e "${INFO}${YW}Admin credentials: ~/zitadel.creds (inside the container)${CL}"
