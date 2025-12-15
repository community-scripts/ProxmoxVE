#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/homarr-labs/homarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  redis-server \
  nginx \
  gettext \
  openssl \
  musl-dev
msg_ok "Installed Dependencies"

NODE_VERSION=$(curl -s https://raw.githubusercontent.com/homarr-labs/homarr/dev/package.json | jq -r '.engines.node | split(">=")[1] | split(".")[0]')
setup_nodejs
fetch_and_deploy_gh_release "homarr" "homarr-labs/homarr" "prebuild" "latest" "/opt/homarr" "build-amd64.tar.gz"

msg_info "Installing Homarr"
# fix musl issues because homarr compiles on alpine not debian soure: https://github.com/alexander-akhmetov/python-telegram/issues/3
ln -s /usr/lib/x86_64-linux-musl/libc.so /lib/libc.musl-x86_64.so.1
mkdir -p /opt/homarr_db
touch /opt/homarr_db/db.sqlite
SECRET_ENCRYPTION_KEY="$(openssl rand -hex 32)"
cd /opt/homarr
cat <<EOF >/opt/homarr.env
DB_DRIVER='better-sqlite3'
DB_DIALECT='sqlite'
SECRET_ENCRYPTION_KEY='${SECRET_ENCRYPTION_KEY}'
DB_URL='/opt/homarr_db/db.sqlite'
TURBO_TELEMETRY_DISABLED=1
AUTH_PROVIDERS='credentials'
NODE_ENV='production'
REDIS_IS_EXTERNAL='true'
EOF
msg_ok "Installed Homarr"

msg_info "Copying config files"
mkdir -p /appdata/redis
chown -R redis:redis /appdata/redis
chmod 744 /appdata/redis
cp /opt/homarr/redis.conf /etc/redis/redis.conf
rm /etc/nginx/nginx.conf
mkdir -p /etc/nginx/templates
cp /opt/homarr/nginx.conf /etc/nginx/templates/nginx.conf
echo $'#!/bin/bash\ncd /opt/homarr/apps/cli && node ./cli.cjs "$@"' >/usr/bin/homarr
chmod +x /usr/bin/homarr
msg_ok "Copied config files"

msg_info "Creating Services"
mkdir -p /etc/systemd/system/redis-server.service.d/
cat <<EOF >/etc/systemd/system/redis-server.service.d/override.conf
[Service]
ReadWritePaths=-/appdata/redis -/var/lib/redis -/var/log/redis -/var/run/redis -/etc/redis
EOF
cat <<EOF >/etc/systemd/system/homarr.service
[Unit]
Description=Homarr Service
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/homarr
EnvironmentFile=-/opt/homarr.env
ExecStart=/opt/homarr/run.sh

[Install]
WantedBy=multi-user.target
EOF
chmod +x /opt/homarr/run.sh
systemctl daemon-reload
systemctl enable -q --now redis-server && sleep 5
systemctl enable -q --now homarr
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
