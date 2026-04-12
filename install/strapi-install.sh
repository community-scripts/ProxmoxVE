#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pespinel
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://strapi.io/

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
  python3-setuptools \
  libvips42
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

msg_info "Installing Strapi (Patience)"
mkdir -p /opt/strapi
cd /opt/strapi
$STD npx --yes create-strapi-app@latest . --quickstart --no-run --skip-cloud
msg_ok "Installed Strapi"

msg_info "Building Strapi"
cd /opt/strapi
export NODE_OPTIONS="--max-old-space-size=3072"
$STD npm run build
msg_ok "Built Strapi"

msg_info "Creating Service"
cat <<EOF >/opt/strapi/.env
HOST=0.0.0.0
PORT=1337
APP_KEYS=$(openssl rand -base64 32)
API_TOKEN_SALT=$(openssl rand -base64 32)
ADMIN_JWT_SECRET=$(openssl rand -base64 32)
TRANSFER_TOKEN_SALT=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)
EOF
cat <<EOF >/etc/systemd/system/strapi.service
[Unit]
Description=Strapi CMS
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/strapi
EnvironmentFile=/opt/strapi/.env
ExecStart=/usr/bin/npm run start
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now strapi
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
