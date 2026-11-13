#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/get-convex/convex-backend

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "convex" "get-convex/convex-backend" "prebuild" "latest" "/opt/convex" "convex-local-backend-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
fetch_and_deploy_gh_release "convex-dashboard" "get-convex/convex-backend" "prebuild" "$(cat ~/.convex)" "/opt/convex-dashboard" "dashboard.zip"

msg_info "Configuring Convex"
mkdir -p /opt/convex_data/storage /opt/convex_data/tmp
INSTANCE_SECRET=$(openssl rand -hex 32)
ADMIN_KEY=$(/opt/convex/convex-local-backend keygen admin-key --instance-name convex-self-hosted --instance-secret "$INSTANCE_SECRET")
cat <<EOF >/opt/convex_data/.env
INSTANCE_NAME=convex-self-hosted
INSTANCE_SECRET=${INSTANCE_SECRET}
CONVEX_SELF_HOSTED_ADMIN_KEY="${ADMIN_KEY}"
CONVEX_CLOUD_ORIGIN=http://${LOCAL_IP}:3210
CONVEX_SITE_ORIGIN=http://${LOCAL_IP}:3211
TMPDIR=/opt/convex_data/tmp
RUST_LOG=info
DOCUMENT_RETENTION_DELAY=172800
DISABLE_METRICS_ENDPOINT=true
APPLICATION_MAX_CONCURRENT_MUTATIONS=16
APPLICATION_MAX_CONCURRENT_QUERIES=16
APPLICATION_MAX_CONCURRENT_V8_ACTIONS=16
APPLICATION_MAX_CONCURRENT_NODE_ACTIONS=16
EOF
chmod 600 /opt/convex_data/.env
msg_ok "Configured Convex"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/convex-dashboard
server {
    listen 6791;
    server_name _;
    root /opt/convex-dashboard;
    index index.html;

    location / {
        try_files \$uri \$uri.html \$uri/ =404;
    }
}
EOF
nginx_enable_site "convex-dashboard"
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/convex.service
[Unit]
Description=Convex Backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/convex_data
EnvironmentFile=/opt/convex_data/.env
ExecStart=/opt/convex/convex-local-backend --instance-name \${INSTANCE_NAME} --instance-secret \${INSTANCE_SECRET} --port 3210 --site-proxy-port 3211 --convex-origin \${CONVEX_CLOUD_ORIGIN} --convex-site \${CONVEX_SITE_ORIGIN} --local-storage /opt/convex_data/storage /opt/convex_data/db.sqlite3
KillSignal=SIGINT
TimeoutStopSec=10
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now convex
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
