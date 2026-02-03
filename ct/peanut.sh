#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Brandawg93/PeaNUT/

APP="PeaNUT"
var_tags="${var_tags:-network;ups}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-7}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

WEB_UI_PORT=8080
WEB_UI_PROTOCOL="http"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/peanut.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs

  if check_for_gh_release "peanut" "Brandawg93/PeaNUT"; then
    msg_info "Stopping Service"
    systemctl stop peanut
    msg_info "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "peanut" "Brandawg93/PeaNUT" "tarball" "latest" "/opt/peanut"

    if ! grep -q '/opt/peanut/entrypoint.mjs' /etc/systemd/system/peanut.service; then
      msg_info "Fixing entrypoint"
      cd /opt/peanut
      ln -sf .next/standalone/server.js server.js
      sed -i 's|/opt/peanut/.next/standalone/server.js|/opt/peanut/entrypoint.mjs|' /etc/systemd/system/peanut.service
      systemctl daemon-reload
      msg_ok "Fixed entrypoint"
    fi

    msg_info "Updating Peanut"
    cd /opt/peanut
    $STD pnpm i
    $STD pnpm run build:local
    cp -r .next/static .next/standalone/.next/
    mkdir -p /opt/peanut/.next/standalone/config
    ln -sf /etc/peanut/settings.yml /opt/peanut/.next/standalone/config/settings.yml
    msg_ok "Updated Peanut"

    msg_info "Starting Service"
    systemctl start peanut
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
