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

msg_info "Setup Pangolin"
IP_ADDR=$(hostname -I | awk '{print $1}')
SECRET_KEY=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32)
cd /opt/pangolin
$STD npm ci
$STD npm run set:sqlite
$STD npm run set:oss
rm -rf server/private
$STD npm run build:sqlite
$STD npm run build:cli
cp -R .next/standalone ./

cat <<EOF >/usr/local/bin/pangctl
#!/bin/sh
cd /opt/pangolin
./dist/cli.mjs "$@"
EOF
chmod +x /usr/local/bin/pangctl ./dist/cli.mjs
cp server/db/names.json ./dist/names.json
mkdir -p /var/config

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

. /etc/os-release
if [ "$VERSION_CODENAME" = "trixie" ]; then
  echo "net.ipv4.ip_forward=1" >>/etc/sysctl.d/sysctl.conf
  $STD sysctl -p /etc/sysctl.d/sysctl.conf
else
  echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
  $STD sysctl -p /etc/sysctl.conf
fi
msg_ok "Setup Pangolin"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/pangolin.service
[Unit]
Description=Pangolin Service
After=network.target

[Service]
Type=simple
User=root
Environment=NODE_ENV=production
Environment=ENVIRONMENT=prod
WorkingDirectory=/opt/pangolin
ExecStart=/usr/bin/node --enable-source-maps dist/server.mjs
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pangolin

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
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
