#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nxzai/nextExplorer

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  ripgrep \
  imagemagick \
  ffmpeg \
  libva-drm2 \
  libva2 \
  mesa-va-drivers \
  vainfo
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "nextExplorer" "nxzai/nextExplorer" "tarball" "latest" "/opt/nextExplorer"

msg_info "Building nextExplorer"
APP_DIR="/opt/nextExplorer/app"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
mkdir -p "$APP_DIR"
mkdir -p /etc/nextExplorer
cd /opt/nextExplorer
export NODE_ENV=production
$STD npm ci --omit=dev --workspace backend
mv node_modules "$APP_DIR"
mv backend/{src,package.json} "$APP_DIR"
unset NODE_ENV

export NODE_ENV=development
export NODE_OPTIONS="--max-old-space-size=2048"
$STD npm ci --workspace frontend
$STD npm run -w frontend build -- --sourcemap false
unset NODE_ENV
mv frontend/dist/ "$APP_DIR"/src/public
msg_ok "Built nextExplorer"

msg_info "Configuring nextExplorer"
SECRET=$(openssl rand -hex 32)
cat <<EOF >/etc/nextExplorer/.env
NODE_ENV=production
PORT=3000

VOLUME_ROOT=/mnt
CONFIG_DIR=/etc/nextExplorer
CACHE_DIR=/etc/nextExplorer/cache
# USER_ROOT=

PUBLIC_URL=${LOCAL_IP}:3000
# TRUST_PROXY=
# CORS_ORIGINS=

TERMINAL_ENABLED=false

LOG_LEVEL=info
DEBUG=false
ENABLE_HTTP_LOGGING=false

AUTH_ENABLED=true
AUTH_MODE=both
SESSION_SECRET="${SECRET}"
# AUTH_MAX_FAILED=
# AUTH_LOCK_MINUTES=
# AUTH_USER_EMAIL=
# AUTH_USER_PASSWORD=

# OIDC_ENABLED=
# OIDC_ISSUER=
# OIDC_AUTHORIZATION_URL=
# OIDC_TOKEN_URL=
# OIDC_USERINFO_URL=
# OIDC_CLIENT_ID=
# OIDC_CLIENT_SECRET=
# OIDC_CALLBACK_URL=
# OIDC_LOGOUT_URL=
# OIDC_SCOPES=
# OIDC_AUTO_CREATE_USERS=true

# SEARCH_DEEP=
# SEARCH_RIPGREP=
# SEARCH_MAX_FILESIZE=

# ONLYOFFICE_URL=
# ONLYOFFICE_SECRET=
# ONLYOFFICE_LANG=
# ONLYOFFICE_FORCE_SAVE=
# ONLYOFFICE_FILE_EXTENSIONS=

# COLLABORA_URL=
# COLLABORA_DISCOVERY_URL=
# COLLABORA_SECRET=
# COLLABORA_LANG=
# COLLABORA_FILE_EXTENSIONS=

SHOW_VOLUME_USAGE=true
# USER_DIR_ENABLED=
# SKIP_HOME=

# EDITOR_EXTENSIONS=

# FFMPEG_PATH=
# FFPROBE_PATH=

## Hardware acceleration
# FFMPEG_HWACCEL=vaapi
# FFMPEG_HWACCEL_DEVICE=/dev/dri/renderD128
# FFMPEG_HWACCEL_OUTPUT_FORMAT=nv12

FAVORITES_DEFAULT_ICON=outline.StarIcon

SHARES_ENABLED=true
# SHARES_TOKEN_LENGTH=10
# SHARES_MAX_PER_USER=100
# SHARES_DEFAULT_EXPIRY_DAYS=30
# SHARES_GUEST_SESSION_HOURS=24
# SHARES_ALLOW_PASSWORD=true
# SHARES_ALLOW_ANONYMOUS=true
EOF
chmod 600 /etc/nextExplorer/.env
$STD useradd -U -s /usr/sbin/nologin -m -d /home/explorer explorer
chown -R explorer:explorer "$APP_DIR" /etc/nextExplorer
sed -i "\|version|s|$(jq -cr '.version' ${APP_DIR}/package.json)|$(cat ~/.nextexplorer)|" "$APP_DIR"/package.json
msg_ok "Configured nextExplorer"

msg_info "Creating nextExplorer Service"
cat <<EOF >/etc/systemd/system/nextexplorer.service
[Unit]
Description=nextExplorer Service
After=network.target

[Service]
Type=simple
User=explorer
Group=explorer
WorkingDirectory=/opt/nextExplorer/app
EnvironmentFile=/etc/nextExplorer/.env
ExecStart=/usr/bin/node ./src/server.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now nextexplorer
msg_ok "Created nextExplorer Service"

motd_ssh
customize
cleanup_lxc
