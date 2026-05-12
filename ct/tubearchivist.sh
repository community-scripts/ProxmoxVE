#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tubearchivist/tubearchivist

APP="Tube Archivist"
var_tags="${var_tags:-media;youtube;archiving}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-30}"
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

  if [[ ! -d /opt/tubearchivist ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "tubearchivist" "tubearchivist/tubearchivist"; then
    msg_info "Stopping Services"
    systemctl stop tubearchivist tubearchivist-celery tubearchivist-beat
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/tubearchivist/.env /opt/tubearchivist_env.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tubearchivist" "tubearchivist/tubearchivist" "tarball"

    msg_info "Rebuilding Tube Archivist"
    cd /opt/tubearchivist/frontend
    $STD npm install
    $STD npm run build:deploy
    mkdir -p /opt/tubearchivist/backend/static
    cp -r /opt/tubearchivist/frontend/dist/* /opt/tubearchivist/backend/static/
    cp /opt/tubearchivist/docker_assets/backend_start.py /opt/tubearchivist/backend/
    $STD uv pip install --python /opt/tubearchivist/.venv/bin/python -r /opt/tubearchivist/backend/requirements.txt
    if [[ -f /opt/tubearchivist/backend/requirements.plugins.txt ]]; then
      mkdir -p /opt/yt_plugins/bgutil
      $STD uv pip install --python /opt/tubearchivist/.venv/bin/python --target /opt/yt_plugins/bgutil -r /opt/tubearchivist/backend/requirements.plugins.txt
    fi
    msg_ok "Rebuilt Tube Archivist"

    msg_info "Restoring Configuration"
    mv /opt/tubearchivist_env.bak /opt/tubearchivist/.env
    sed -i 's|^TA_APP_DIR=/opt/tubearchivist$|TA_APP_DIR=/opt/tubearchivist/backend|' /opt/tubearchivist/.env
    sed -i 's|^TA_CACHE_DIR=/opt/tubearchivist/cache$|TA_CACHE_DIR=/cache|' /opt/tubearchivist/.env
    sed -i 's|^TA_MEDIA_DIR=/opt/tubearchivist/media$|TA_MEDIA_DIR=/youtube|' /opt/tubearchivist/.env
    ln -sf /opt/tubearchivist/cache /cache
    ln -sf /opt/tubearchivist/media /youtube
    ln -sf /opt/tubearchivist/.env /opt/tubearchivist/backend/.env
    msg_ok "Restored Configuration"

    msg_info "Starting Services"
    systemctl start tubearchivist tubearchivist-celery tubearchivist-beat
    systemctl reload nginx
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
