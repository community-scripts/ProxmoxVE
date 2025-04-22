#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz) & vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://karakeep.app/

APP="karakeep"
var_tags="${var_tags:-bookmark}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/karakeep ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/karakeep-app/karakeep/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  PREV_RELEASE=$(cat /opt/${APP}_version.txt)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "${PREV_RELEASE}" ]]; then
    msg_info "Stopping Services"
    systemctl stop karakeep-web karakeep-workers karakeep-browser
    msg_ok "Stopped Services"
    msg_info "Updating yt-dlp"
    $STD yt-dlp --update-to nightly
    msg_ok "Updated yt-dlp"
    msg_info "Updating ${APP} to v${RELEASE}"
    if [[ $(corepack -v) < "0.31.0" ]]; then
      $STD npm install -g corepack@0.31.0
    fi
    if [[ "${PREV_RELEASE}" < 0.23.0 ]]; then
      $STD apt-get install -y graphicsmagick ghostscript
    fi
    cd /opt
    if [[ -f /opt/karakeep/.env ]] && [[ ! -f /etc/karakeep/karakeep.env ]]; then
      mkdir -p /etc/karakeep
      mv /opt/karakeep/.env /etc/karakeep/karakeep.env
    fi
    rm -rf /opt/karakeep
    curl -fsSL "https://github.com/karakeep-app/karakeep/archive/refs/tags/v${RELEASE}.zip" -o "v${RELEASE}.zip"
    unzip -q "v${RELEASE}.zip"
    mv karakeep-"${RELEASE}" /opt/karakeep
    cd /opt/karakeep/apps/web
    $STD pnpm install --frozen-lockfile
    $STD pnpm exec next build --experimental-build-mode compile
    cp -r /opt/karakeep/apps/web/.next/standalone/apps/web/server.js /opt/karakeep/apps/web
    cd /opt/karakeep/apps/workers
    $STD pnpm install --frozen-lockfile
    export DATA_DIR=/opt/karakeep_data
    cd /opt/karakeep/packages/db
    $STD pnpm migrate
    sed -i "s/SERVER_VERSION=${PREV_RELEASE}/SERVER_VERSION=${RELEASE}/" /etc/karakeep/karakeep.env
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Services"
    systemctl start karakeep-browser karakeep-workers karakeep-web
    msg_ok "Started Services"
    msg_info "Cleaning up"
    rm -R /opt/v"${RELEASE}".zip
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required.  ${APP} is already at ${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
