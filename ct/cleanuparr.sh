#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Lucas Zampieri (zampierilucas) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Cleanuparr/Cleanuparr

APP="Cleanuparr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
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
  if [[ ! -f /opt/cleanuparr/Cleanuparr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "cleanuparr" "Cleanuparr/Cleanuparr"; then
    msg_info "Stopping Service"
    systemctl stop cleanuparr
    msg_ok "Stopped Service"

    if [[ ! -d /etc/cleanuparr ]]; then
      msg_info "Migrating Configuration to /etc/cleanuparr"
      mv /opt/cleanuparr/config /etc/cleanuparr
      mkdir -p /etc/cleanuparr /var/log/cleanuparr
      rm -rf /etc/cleanuparr/logs
      sed -i -e 's|^Environment="CONFIG_DIR=.*|Environment="CLEANUPARR_CONFIG_PATH=/etc/cleanuparr"|' \
        -e '/^Environment="CLEANUPARR_CONFIG_PATH=/a Environment="CLEANUPARR_LOGS_PATH=/var/log/cleanuparr"' \
        /etc/systemd/system/cleanuparr.service
      systemctl daemon-reload
      msg_ok "Migrated Configuration to /etc/cleanuparr"
    fi

    create_backup /etc/cleanuparr

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Cleanuparr" "Cleanuparr/Cleanuparr" "prebuild" "latest" "/opt/cleanuparr" "*linux-$(arch_resolve).zip"

    restore_backup

    msg_info "Starting Service"
    systemctl start cleanuparr
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
echo -e "${GATEWAY}${BGN}http://${IP}:11011${CL}"
