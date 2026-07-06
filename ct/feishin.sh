#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jeffvli/feishin

APP="Feishin"
var_tags="${var_tags:-music;player;streaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/feishin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

  if check_for_gh_release "feishin" "jeffvli/feishin"; then
    create_backup /opt/feishin/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "feishin" "jeffvli/feishin" "tarball"

    msg_info "Rebuilding Feishin Web"
    cd /opt/feishin
    #PNPM_VERSION=$(jq -r '.packageManager | ltrimstr("pnpm@")' /opt/feishin/package.json)

    $STD corepack prepare "pnpm@10" --activate
    $STD pnpm install
    $STD pnpm run build:web
    msg_ok "Rebuilt Feishin Web"

    restore_backup

    msg_info "Publishing Web Assets"
    rm -rf /usr/share/nginx/html
    mkdir -p /usr/share/nginx/html
    cp -r /opt/feishin/out/web/. /usr/share/nginx/html/

    set -a
    source /opt/feishin/.env
    set +a

    envsubst </opt/feishin/settings.js.template >/etc/nginx/conf.d/settings.js
    envsubst '${PUBLIC_PATH}' </opt/feishin/ng.conf.template >/etc/nginx/sites-available/feishin
    ln -sf /etc/nginx/sites-available/feishin /etc/nginx/sites-enabled/feishin
    rm -f /etc/nginx/sites-enabled/default
    systemctl restart nginx
    msg_ok "Published Web Assets"

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
echo -e "${GATEWAY}${BGN}http://${IP}:9180${CL}"
