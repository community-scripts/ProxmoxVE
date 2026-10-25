#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/emdash-cms/emdash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" NODE_MODULE="pnpm@11" setup_nodejs

msg_info "Creating EmDash Site"
cd /opt
$STD pnpm dlx create-emdash@latest emdash --platform node --template "${var_emdash_template:-blog}" --pm pnpm --no-install --yes
mkdir -p /opt/emdash_data/uploads
mv /opt/emdash/.env /opt/emdash_data/.env
sed -i -e 's|file:./data.db|file:/opt/emdash_data/data.db|' -e 's|"./uploads"|"/opt/emdash_data/uploads"|' /opt/emdash/astro.config.mjs
cat <<EOF >>/opt/emdash_data/.env
HOST=0.0.0.0
PORT=4321
# The address in the browser bar. Passkeys are bound to its hostname, and the build bakes it in for image optimization:
# after a change run cd /opt/emdash && set -a && . /opt/emdash_data/.env && set +a && pnpm build && systemctl restart emdash
EMDASH_SITE_URL=${var_emdash_url:-http://${LOCAL_IP}:4321}
EOF
chmod 600 /opt/emdash_data/.env
msg_ok "Created EmDash Site"

msg_info "Building EmDash"
cd /opt/emdash
# pnpm keeps Astro's sharp out of the site's reach, and every /_image request then fails with MissingSharp
$STD pnpm add sharp
set -a && source /opt/emdash_data/.env && set +a
$STD pnpm build
cat <<EOF >~/.emdash
emdash@$(node -p 'require("/opt/emdash/node_modules/emdash/package.json").version')
EOF
msg_ok "Built EmDash"

msg_info "Creating EmDash Service"
cat <<EOF >/etc/systemd/system/emdash.service
[Unit]
Description=EmDash
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/emdash
EnvironmentFile=/opt/emdash_data/.env
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /opt/emdash/dist/server/entry.mjs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now emdash
msg_ok "Created EmDash Service"

motd_ssh
customize
cleanup_lxc
