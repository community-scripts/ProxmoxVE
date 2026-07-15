#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner | vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://musicseerr.com/ | Github: https://github.com/HabiRabbu/Musicseerr

APP="MusicSeerr"
var_tags="${var_tags:-arr;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/musicseerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "droppedneedle" "DroppedNeedle/DroppedNeedle"; then
    msg_warn "Migrating Musicseerr to DroppedNeedle"
    msg_info "Stopping Service"
    systemctl disable -q --now musicseerr
    msg_ok "Stopped Service"

    msg_info "Backing up Musicseerr Data"
    cp -a /opt/musicseerr/backend/config /opt/musicseerr_config_backup
    cp -a /opt/musicseerr/backend/cache /opt/musicseerr_cache_backup
    msg_ok "Backed up Musicseerr Data"

    PYTHON_VERSION="3.13" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "droppedneedle" "DroppedNeedle/DroppedNeedle" "tarball"
    NODE_VERSION="25" NODE_MODULE="pnpm@10.33.0" setup_nodejs

    msg_info "Building DroppedNeedle Frontend"
    cd /opt/droppedneedle/frontend
    export NODE_OPTIONS="--max-old-space-size=3072"
    rm -rf node_modules build
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    msg_ok "Built DroppedNeedle Frontend"

    msg_info "Building DroppedNeedle backend"
    mkdir -p /opt/droppedneedle/backend/config /opt/droppedneedle/backend/cache
    $STD uv venv /opt/droppedneedle/venv
    $STD uv pip install -r /opt/droppedneedle/backend/requirements.txt --python=/opt/droppedneedle/venv/bin/python
    rm -rf /opt/droppedneedle/backend/static
    cp -r /opt/droppedneedle/frontend/build /opt/droppedneedle/backend/static
    msg_ok "Built DroppedNeedle backend"

    msg_info "Restoring Data from Musicseerr"
    rm -rf /opt/droppedneedle/backend/config /opt/droppedneedle/backend/cache
    cp -a /opt/musicseerr_config_backup/. /opt/droppedneedle/backend/config/
    cp -a /opt/musicseerr_cache_backup/. /opt/droppedneedle/backend/cache/
    msg_ok "Restored Data from Musicseerr"

    msg_info "Replacing systemd service file"
    cat <<EOF >/etc/systemd/system/droppedneedle.service
[Unit]
Description=DroppedNeedle Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/droppedneedle/backend
Environment=ROOT_APP_DIR=/opt/droppedneedle/backend
Environment=PORT=8688
# Environment=SLSKD_DOWNLOADS_PATH=<path-to-slskd-downloads>
ExecStart=/opt/droppedneedle/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8688 --loop uvloop --http httptools --workers 1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    rm -f /etc/systemd/system/musicseerr.service
    msg_ok "Replaced systemd service file"

    msg_info "Enabling DroppedNeedle Service"
    systemctl enable -q --now droppedneedle
    msg_ok "Enabled DroppedNeedle Service"
    rm -rf /opt/musicseerr_config_backup /opt/musicseerr_cache_backup
    cp /bin/update /bin/update.bak
    sed -i 's/musicseerr/droppedneedle/' /bin/update
    rm -rf /opt/musicseerr
    msg_ok "Migrated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8688${CL}"
