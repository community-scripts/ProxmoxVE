#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fccview/degoog

APP="degoog"
var_tags="${var_tags:-search;privacy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/degoog ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "degoog" "fccview/degoog"; then
    msg_info "Stopping Service"
    systemctl stop degoog
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration & Data"
    [[ -f /opt/degoog/.env ]] && cp /opt/degoog/.env /opt/degoog.env.bak
    [[ -d /opt/degoog/data ]] && mv /opt/degoog/data /opt/degoog_data_backup
    msg_ok "Backed up Configuration & Data"

    if ! command -v bun >/dev/null 2>&1; then
      msg_info "Installing Bun"
      export BUN_INSTALL="/root/.bun"
      curl -fsSL https://bun.sh/install | $STD bash
      ln -sf /root/.bun/bin/bun /usr/local/bin/bun
      ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
      msg_ok "Installed Bun"
    fi

    msg_info "Updating Valkey"
    $STD apt install -y --only-upgrade valkey
    msg_ok "Updated Valkey"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "degoog" "fccview/degoog" "prebuild" "latest" "/opt/degoog" "degoog_*_prebuild.tar.gz"

    msg_info "Restoring Configuration & Data"
    [[ -f /opt/degoog.env.bak ]] && mv /opt/degoog.env.bak /opt/degoog/.env
    [[ -d /opt/degoog_data_backup ]] && mv /opt/degoog_data_backup /opt/degoog/data
    msg_ok "Restored Configuration & Data"

    msg_info "Starting Service"
    systemctl start degoog
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4444${CL}"
