#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pangolin.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  sqlite3 \
  iptables
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "pangolin" "fosrl/pangolin" "tarball"
fetch_and_deploy_gh_release "gerbil" "fosrl/gerbil" "singlefile" "latest" "/usr/bin" "gerbil_linux_amd64"
IP_ADDR=$(hostname -I | awk '{print $1}')
SECRET_KEY=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32)

msg_info "Setup Pangolin (Patience)"
export BUILD=oss
export DATABASE=sqlite
cd /opt/pangolin
$STD npm ci
echo "export * from \"./$DATABASE\";" > server/db/index.ts
echo "export const build = \"$BUILD\" as any;" > server/build.ts
cp tsconfig.oss.json tsconfig.json
mkdir -p dist
$STD npm run next:build
$STD node esbuild.mjs -e server/index.ts -o dist/server.mjs -b $BUILD
$STD node esbuild.mjs -e server/setup/migrationsSqlite.ts -o dist/migrations.mjs
$STD npm run build:cli
cp -R .next/standalone ./

cat <<EOF >/usr/local/bin/pangctl
#!/bin/sh
cd /opt/pangolin
./dist/cli.mjs "$@"
EOF
chmod +x /usr/local/bin/pangctl ./dist/cli.mjs
cp server/db/names.json ./dist/names.json

cat <<EOF >/opt/pangolin/config/config.yml
app:
  dashboard_url: http://$IP_ADDR:3002
  log_level: debug

domains:
  domain1:
    base_domain: example.com

server:
  secret: $SECRET_KEY

gerbil:
  base_endpoint: example.com

orgs:
  block_size: 24
  subnet_group: 100.90.137.0/20

flags:
  require_email_verification: false
  disable_signup_without_invite: true
  disable_user_create_org: true
  allow_raw_resources: true
  enable_integration_api: true
  enable_clients: true
EOF
$STD npm run db:sqlite:generate
$STD npm run db:sqlite:push
msg_ok "Setup Pangolin"

msg_info "Creating Pangolin Service"
cat <<EOF >/etc/systemd/system/pangolin.service
[Unit]
Description=Pangolin Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pangolin
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pangolin
msg_ok "Created pangolin Service"

msg_info "Setting up gerbil"
mkdir -p /var/config
cat <<EOF >/etc/systemd/system/gerbil.service
[Unit]
Description=Gerbil Service
After=network.target
Requires=pangolin.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/gerbil --reachableAt=http://$IP_ADDR:3004 --generateAndSaveKeyTo=/var/config/key --remoteConfig=http://$IP_ADDR:3001/api/v1/
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gerbil
msg_ok "Set up gerbil"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
