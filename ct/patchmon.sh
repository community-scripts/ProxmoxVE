#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PatchMon/PatchMon

APP="PatchMon"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d "/opt/patchmon" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs
  if check_for_gh_release "PatchMon" "PatchMon/PatchMon"; then
    msg_info "Stopping Service"
    systemctl stop patchmon-server
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    cp /opt/patchmon/backend/.env /opt/backend.env
    cp /opt/patchmon/frontend/.env /opt/frontend.env
    msg_ok "Backup Created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "PatchMon" "PatchMon/PatchMon" "tarball" "latest" "/opt/patchmon"

    msg_info "Updating PatchMon"
    VERSION=$(get_latest_github_release "PatchMon/PatchMon")
    PROTO="$(sed -n '/SERVER_PROTOCOL/s/[^=]*=//p' /opt/backend.env)"
    HOST="$(sed -n '/SERVER_HOST/s/[^=]*=//p' /opt/backend.env)"
    [[ "$PROTO" == "http" ]] && PORT=":3001"
    export NODE_ENV=production
    cd /opt/patchmon
    $STD npm install --no-audit --no-fund --no-save --ignore-scripts
    cd /opt/patchmon/frontend
    mv /opt/frontend.env /opt/patchmon/frontend/.env
    sed -i -e "s/VERSION=.*/VERSION=$VERSION/" \
      -e "\|VITE_API_URL=|s|http.*|${PROTO:-http}://${HOST:-$LOCAL_IP}${PORT:-}/api/v1|" ./.env
    $STD npm install --no-audit --no-fund --no-save --ignore-scripts --include=dev
    $STD npm run build
    cd /opt/patchmon/backend
    mv /opt/backend.env /opt/patchmon/backend/.env
    sed -i 's/PORT=3399/PORT=3001/' /opt/patchmon/backend/.env
    $STD npm run db:generate
    $STD npx prisma migrate deploy
    cp /opt/patchmon/docker/nginx.conf.template /etc/nginx/sites-available/patchmon.conf
    sed -i -e 's|proxy_pass .*|proxy_pass http://127.0.0.1:3001;|' \
      -e '\|try_files |i\        root /opt/patchmon/frontend/dist;' \
      -e 's|alias.*|alias /opt/patchmon/frontend/dist/assets;|' \
      -e '\|expires 1y|i\        root /opt/patchmon/frontend/dist;' /etc/nginx/sites-available/patchmon.conf
    ln -sf /etc/nginx/sites-available/patchmon.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    $STD nginx -t
    systemctl restart nginx
    msg_ok "Updated PatchMon"

    msg_info "Starting Service"
    if grep -q '/usr/bin/node' /etc/systemd/system/patchmon-server.service; then
      sed -i 's|ExecStart=.*|ExecStart=/usr/bin/npm run start|' /etc/systemd/system/patchmon-server.service
      systemctl daemon-reload
    fi
    systemctl start patchmon-server
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
