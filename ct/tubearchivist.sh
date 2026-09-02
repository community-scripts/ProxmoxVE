#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
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

  if [[ ! -d /opt/tubearchivist ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ ! -f /etc/systemd/system/bgutil-provider.service ]]; then
    msg_info "Adding BgUtil POT Provider"
    ensure_dependencies ffmpeg libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev pkg-config
    fetch_and_deploy_gh_release "bgutil-ytdlp-pot-provider" "Brainicism/bgutil-ytdlp-pot-provider" "tarball"
    cd /opt/bgutil-ytdlp-pot-provider/server
    $STD npm ci
    $STD npx tsc
    cat <<EOF >/etc/systemd/system/bgutil-provider.service
[Unit]
Description=BgUtil YT-DLP POT Provider
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/bgutil-ytdlp-pot-provider/server
ExecStart=/usr/bin/node build/main.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable -q --now bgutil-provider
    msg_ok "Added BgUtil POT Provider"
  fi

  if check_for_gh_release "tubearchivist" "tubearchivist/tubearchivist"; then
    msg_info "Stopping Services"
    systemctl stop bgutil-provider tubearchivist tubearchivist-celery tubearchivist-beat
    msg_ok "Stopped Services"

    create_backup \
      /opt/tubearchivist/.env \
      /opt/tubearchivist/cache \
      /opt/tubearchivist/backend/run.sh

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tubearchivist" "tubearchivist/tubearchivist" "tarball"

    restore_backup

    msg_info "Rebuilding Tube Archivist"
    cd /opt/tubearchivist/frontend
    $STD npm install
    $STD npm run build:deploy
    mkdir -p /opt/tubearchivist/backend/static
    cp -r /opt/tubearchivist/frontend/dist/* /opt/tubearchivist/backend/static/
    cp /opt/tubearchivist/docker_assets/backend_start.py /opt/tubearchivist/backend/
    rm -rf /opt/tubearchivist/.venv
    $STD uv venv /opt/tubearchivist/.venv --python 3.13
    $STD uv pip install --python /opt/tubearchivist/.venv/bin/python -r /opt/tubearchivist/backend/requirements.txt
    if [[ -f /opt/tubearchivist/backend/requirements.plugins.txt ]]; then
      mkdir -p /opt/yt_plugins/bgutil
      $STD uv pip install --python /opt/tubearchivist/.venv/bin/python --target /opt/yt_plugins/bgutil -r /opt/tubearchivist/backend/requirements.plugins.txt
    fi
    $STD uv pip install --python /opt/tubearchivist/.venv/bin/python -U --prerelease allow "yt-dlp[default]"
    msg_ok "Rebuilt Tube Archivist"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bgutil-ytdlp-pot-provider" "Brainicism/bgutil-ytdlp-pot-provider" "tarball"

    msg_info "Rebuilding BgUtil POT Provider"
    cd /opt/bgutil-ytdlp-pot-provider/server
    $STD npm ci
    $STD npx tsc
    msg_ok "Rebuilt BgUtil POT Provider"

    msg_info "Restoring Configuration"
    sed -i 's|^TA_APP_DIR=/opt/tubearchivist$|TA_APP_DIR=/opt/tubearchivist/backend|' /opt/tubearchivist/.env
    sed -i 's|^TA_CACHE_DIR=/opt/tubearchivist/cache$|TA_CACHE_DIR=/cache|' /opt/tubearchivist/.env
    sed -i 's|^TA_MEDIA_DIR=/opt/tubearchivist/media$|TA_MEDIA_DIR=/youtube|' /opt/tubearchivist/.env
    ln -sfn /opt/tubearchivist/cache /cache
    # /youtube may already be a user-managed Proxmox bind mount. Only create the symlink if nothing is there
    if [[ ! -e /youtube ]]; then
      mkdir -p /opt/tubearchivist/media
      ln -sfn /opt/tubearchivist/media /youtube
    elif ! mountpoint -q /youtube && [[ ! -L /youtube ]]; then
      msg_error "/youtube exists but is neither a mount nor a symlink - check manually"
    fi   
    ln -sf /opt/tubearchivist/.env /opt/tubearchivist/backend/.env
    msg_ok "Restored Configuration"

    msg_info "Starting Services"
    systemctl start bgutil-provider tubearchivist tubearchivist-celery tubearchivist-beat
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
