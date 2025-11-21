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
  if [[ ! -d /opt/karakeep ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "karakeep" "karakeep-app/karakeep"; then
    msg_info "Stopping Services"
    systemctl stop karakeep-web karakeep-workers karakeep-browser
    msg_ok "Stopped Services"

    msg_info "Updating yt-dlp"
    $STD yt-dlp --update-to nightly
    msg_ok "Updated yt-dlp"

    msg_info "Prepare update"
    $STD apt install -y graphicsmagick ghostscript
    if [[ -f /opt/karakeep/.env ]] && [[ ! -f /etc/karakeep/karakeep.env ]]; then
      mkdir -p /etc/karakeep
      mv /opt/karakeep/.env /etc/karakeep/karakeep.env
    fi
    msg_ok "Update prepared"

    if grep -q "start:prod" /etc/systemd/system/karakeep-workers.service; then
      sed -i 's|^ExecStart=.*$|ExecStart=/usr/bin/node dist/index.mjs|' /etc/systemd/system/karakeep-workers.service
      systemctl daemon-reload
    fi

    if grep -q '^ExecStart=/usr/bin/node\s\+dist/index\.mjs$' /etc/systemd/system/karakeep-workers.service; then
      sed -i -E 's#^(ExecStart=/usr/bin/node\s+dist/)index\.mjs$#\1index.js#' /etc/systemd/system/karakeep-workers.service
      systemctl daemon-reload
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "karakeep" "karakeep-app/karakeep"
    if command -v corepack >/dev/null; then
      $STD corepack disable
    fi
    MODULE_VERSION="$(jq -r '.packageManager | split("@")[1]' /opt/karakeep/package.json)"
    NODE_VERSION="22" NODE_MODULE="pnpm@${MODULE_VERSION}" setup_nodejs

    msg_info "Updating Karakeep"
    corepack enable
    export PUPPETEER_SKIP_DOWNLOAD="true"
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD="true"
    export NEXT_TELEMETRY_DISABLED=1
    export CI="true"
    cd /opt/karakeep/apps/web
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    cd /opt/karakeep/apps/workers
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    cd /opt/karakeep/apps/cli
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    DATA_DIR="$(sed -n '/^DATA_DIR/p' /etc/karakeep/karakeep.env | awk -F= '{print $2}' | tr -d '="=')"
    export DATA_DIR="${DATA_DIR:-/opt/karakeep_data}"
    cd /opt/karakeep/packages/db
    $STD pnpm migrate
    $STD pnpm store prune
    sed -i "s/^SERVER_VERSION=.*$/SERVER_VERSION=${CHECK_UPDATE_RELEASE#v}/" /etc/karakeep/karakeep.env
    msg_ok "Updated Karakeep"

    msg_info "Starting Services"
    systemctl start karakeep-browser karakeep-workers karakeep-web
    msg_ok "Started Services"
    msg_ok "Updated Successfully!"
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
