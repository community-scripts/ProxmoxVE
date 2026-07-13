#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/perber/leafwiki

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "leafwiki" "perber/leafwiki" "singlefile" "latest" "/usr/local/bin" "leafwiki-v*-linux-$(arch_resolve)"

msg_info "Configuring LeafWiki"
mkdir -p /opt/leafwiki/data
mkdir -p /etc/leafwiki
JWT_SECRET=$(openssl rand -hex 32)
ADMIN_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c12)
cat <<EOF >/etc/leafwiki/.env
LEAFWIKI_DATA_DIR=/opt/leafwiki/data
LEAFWIKI_HOST=0.0.0.0
LEAFWIKI_PORT=8080
LEAFWIKI_JWT_SECRET=${JWT_SECRET}
LEAFWIKI_ADMIN_PASSWORD=${ADMIN_PASS}
LEAFWIKI_ALLOW_INSECURE=true
EOF
msg_ok "Configured LeafWiki"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/leafwiki.service
[Unit]
Description=LeafWiki
After=network.target

[Service]
Type=simple
User=root
EnvironmentFile=/etc/leafwiki/.env
ExecStart=/usr/local/bin/leafwiki
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now leafwiki
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
