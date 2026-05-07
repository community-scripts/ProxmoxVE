#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Termix-SSH/Termix

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
  python3 \
  nginx \
  openssl \
  gettext-base \
  libcairo2-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libtool-bin \
  uuid-dev \
  libvncserver-dev \
  freerdp3-dev \
  libssh2-1-dev \
  libtelnet-dev \
  libwebsockets-dev \
  libpulse-dev \
  libvorbis-dev \
  libwebp-dev \
  libssl-dev \
  libpango1.0-dev \
  libswscale-dev \
  libavcodec-dev \
  libavutil-dev \
  libavformat-dev
msg_ok "Installed Dependencies"

msg_info "Building Guacamole Server (guacd)"
fetch_and_deploy_gh_tag "guacd" "apache/guacamole-server" "latest" "/opt/guacamole-server"
cd /opt/guacamole-server
export CPPFLAGS="-Wno-error=deprecated-declarations"
$STD autoreconf -fi
$STD ./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots
$STD make
$STD make install
$STD ldconfig
cd /opt
rm -rf /opt/guacamole-server
msg_ok "Built Guacamole Server (guacd)"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "termix" "Termix-SSH/Termix" "tarball"

msg_info "Building Frontend"
cd /opt/termix
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
find public/fonts -name "*.ttf" ! -name "*Regular.ttf" ! -name "*Bold.ttf" ! -name "*Italic.ttf" -delete 2>/dev/null || true
$STD npm install --ignore-scripts --force
$STD npm cache clean --force
$STD npm run build
msg_ok "Built Frontend"

msg_info "Building Backend"
$STD npm rebuild better-sqlite3 --force
$STD npm run build:backend
msg_ok "Built Backend"

msg_info "Setting up Node Dependencies"
cd /opt/termix
$STD npm ci --only=production --ignore-scripts --force
$STD npm rebuild better-sqlite3 bcryptjs --force
$STD npm cache clean --force
msg_ok "Set up Node Dependencies"

msg_info "Setting up Directories"
mkdir -p /opt/termix/data \
  /opt/termix/uploads \
  /opt/termix/html \
  /opt/termix/nginx \
  /opt/termix/nginx/logs \
  /opt/termix/nginx/cache \
  /opt/termix/nginx/client_body

cp -r /opt/termix/dist/* /opt/termix/html/ 2>/dev/null || true
cp -r /opt/termix/src/locales /opt/termix/html/locales 2>/dev/null || true
cp -r /opt/termix/public/fonts /opt/termix/html/fonts 2>/dev/null || true
msg_ok "Set up Directories"

msg_info "Configuring Nginx"
curl -fsSL "https://raw.githubusercontent.com/Termix-SSH/Termix/main/docker/nginx.conf" -o /etc/nginx/nginx.conf
sed -i '/^master_process/d' /etc/nginx/nginx.conf
sed -i '/^pid \/app\/nginx/d' /etc/nginx/nginx.conf
sed -i 's|/app/html|/opt/termix/html|g' /etc/nginx/nginx.conf
sed -i 's|/app/nginx|/opt/termix/nginx|g' /etc/nginx/nginx.conf
sed -i 's|listen ${PORT};|listen 80;|g' /etc/nginx/nginx.conf

mkdir -p /tmp/nginx
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Creating Service"
mkdir -p /etc/guacamole
cat <<EOF >/etc/guacamole/guacd.conf
[server]
bind_host = 127.0.0.1
bind_port = 4822
EOF

cat <<EOF >/opt/termix/.env
NODE_ENV=production
DATA_DIR=/opt/termix/data
GUACD_HOST=127.0.0.1
GUACD_PORT=4822
EOF

cat <<EOF >/etc/systemd/system/guacd.service
[Unit]
Description=Guacamole Proxy Daemon (guacd)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/guacd -f -b 127.0.0.1 -l 4822
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/termix.service
[Unit]
Description=Termix Backend
After=network.target guacd.service
Wants=guacd.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/termix
EnvironmentFile=/opt/termix/.env
ExecStart=/usr/bin/node /opt/termix/dist/backend/backend/starter.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now guacd termix
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
