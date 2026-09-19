#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Yooooomi/your_spotify

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_mongodb
NODE_VERSION="22" NODE_MODULE="pnpm@^10,serve" setup_nodejs

fetch_and_deploy_gh_release "your-spotify" "Yooooomi/your_spotify" "tarball"

msg_info "Building Your Spotify"
cd /opt/your-spotify
$STD pnpm install --frozen-lockfile
$STD pnpm --filter @your_spotify/server build
$STD pnpm --filter @your_spotify/client build
msg_ok "Built Your Spotify"

var_api_endpoint="${var_api_endpoint:-http://${LOCAL_IP}:8080}"
var_client_endpoint="${var_client_endpoint:-http://${LOCAL_IP}:3000}"
var_spotify_public="${var_spotify_public:-CHANGE_ME}"
var_spotify_secret="${var_spotify_secret:-CHANGE_ME}"

msg_info "Configuring Your Spotify"
cat <<EOF >/opt/your-spotify.env
API_ENDPOINT=${var_api_endpoint}
CLIENT_ENDPOINT=${var_client_endpoint}
SPOTIFY_PUBLIC=${var_spotify_public}
SPOTIFY_SECRET=${var_spotify_secret}
MONGO_ENDPOINT=mongodb://127.0.0.1:27017/your_spotify
TIMEZONE=UTC
LOG_LEVEL=info
PORT=8080
EOF
chmod 600 /opt/your-spotify.env

cp /opt/your-spotify/apps/client/build/variables-template.js /opt/your-spotify/apps/client/build/variables.js
sed -i "s;__API_ENDPOINT__;${var_api_endpoint};g" /opt/your-spotify/apps/client/build/variables.js
sed -i "s#connect-src \(.*\);#connect-src 'self' ${var_api_endpoint}/;#g" /opt/your-spotify/apps/client/build/index.html
msg_ok "Configured Your Spotify"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/your-spotify.service
[Unit]
Description=Your Spotify Server
Wants=network-online.target
After=network-online.target mongod.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/your-spotify/apps/server
EnvironmentFile=/opt/your-spotify.env
ExecStartPre=/usr/bin/node build/index.js --migrate
ExecStart=/usr/bin/node build/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/your-spotify-web.service
[Unit]
Description=Your Spotify Web
Wants=network-online.target
After=network-online.target your-spotify.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/your-spotify/apps/client
ExecStart=serve -s -l tcp://0.0.0.0:3000 /opt/your-spotify/apps/client/build
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now your-spotify your-spotify-web
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
