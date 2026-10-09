#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Chocobozzz/PeerTube

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3-dev \
  unzip \
  redis-server
systemctl enable -q --now redis-server
msg_ok "Installed Dependencies"

setup_ffmpeg
setup_hwaccel
PG_VERSION="17" setup_postgresql
PG_DB_NAME="peertube_prod" PG_DB_USER="peertube" PG_DB_EXTENSIONS="pg_trgm,unaccent" setup_postgresql_db
NODE_VERSION="22" NODE_MODULE="pnpm@^10" setup_nodejs

fetch_and_deploy_gh_release "peertube" "Chocobozzz/PeerTube" "prebuild" "latest" "/opt/peertube" "peertube-v*.zip"

msg_info "Installing Node Dependencies (Patience)"
cd /opt/peertube
$STD npm run install-node-dependencies -- --production
msg_ok "Installed Node Dependencies"

msg_info "Configuring PeerTube"
mkdir -p /opt/peertube_data/{config,storage}
cp /opt/peertube/config/default.yaml /opt/peertube_data/config/default.yaml
cat <<EOF >/opt/peertube_data/config/production.yaml
listen:
  hostname: '0.0.0.0'
  port: 9000

webserver:
  https: false
  hostname: '${LOCAL_IP}'
  port: 9000

secrets:
  peertube: '$(openssl rand -hex 32)'

database:
  hostname: '127.0.0.1'
  port: 5432
  ssl: false
  suffix: '_prod'
  username: 'peertube'
  password: '${PG_DB_PASS}'
  pool:
    max: 5

redis:
  hostname: '127.0.0.1'
  port: 6379
  auth: null
  db: 0

storage:
  tmp: '/opt/peertube_data/storage/tmp/'
  tmp_persistent: '/opt/peertube_data/storage/tmp-persistent/'
  bin: '/opt/peertube_data/storage/bin/'
  avatars: '/opt/peertube_data/storage/avatars/'
  web_videos: '/opt/peertube_data/storage/web-videos/'
  streaming_playlists: '/opt/peertube_data/storage/streaming-playlists/'
  original_video_files: '/opt/peertube_data/storage/original-video-files/'
  redundancy: '/opt/peertube_data/storage/redundancy/'
  logs: '/opt/peertube_data/storage/logs/'
  previews: '/opt/peertube_data/storage/previews/'
  thumbnails: '/opt/peertube_data/storage/thumbnails/'
  storyboards: '/opt/peertube_data/storage/storyboards/'
  torrents: '/opt/peertube_data/storage/torrents/'
  captions: '/opt/peertube_data/storage/captions/'
  cache: '/opt/peertube_data/storage/cache/'
  plugins: '/opt/peertube_data/storage/plugins/'
  well_known: '/opt/peertube_data/storage/well-known/'
  uploads: '/opt/peertube_data/storage/uploads/'
  client_overrides: '/opt/peertube_data/storage/client-overrides/'

admin:
  # Must be a syntactically valid address - PeerTube validates it when creating
  # the root user, and an IP as the domain part is rejected (require_tld).
  email: 'admin@example.com'
EOF
chmod 750 /opt/peertube_data/config
msg_ok "Configured PeerTube"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/peertube.service
[Unit]
Description=PeerTube daemon
Wants=network-online.target
After=network-online.target postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/peertube
Environment=NODE_ENV=production
Environment=NODE_CONFIG_DIR=/opt/peertube_data/config
ExecStart=/usr/bin/node dist/server
Restart=always
RestartSec=5
SyslogIdentifier=peertube

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now peertube
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
