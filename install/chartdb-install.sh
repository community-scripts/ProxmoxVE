#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/chartdb/chartdb

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
fetch_and_deploy_gh_release "chartdb" "chartdb/chartdb" "tarball"

msg_info "Building ChartDB"
cd /opt/chartdb
$STD npm ci
NODE_OPTIONS="--max-old-space-size=4096" $STD npm run build
rm -rf /opt/chartdb/node_modules
msg_ok "Built ChartDB"

msg_info "Configuring ChartDB"
mkdir -p /opt/chartdb_data
cat <<'EOF' >/opt/chartdb_data/config.js
window.env = {
    DISABLE_ANALYTICS: "true",
    // OPENAI_API_KEY: "",
    // OPENAI_API_ENDPOINT: "https://ollama.example.com/v1",
    // LLM_MODEL_NAME: "qwen2.5-coder:7b",
};
EOF
create_self_signed_cert "chartdb"
# HTTPS because the AI export (crypto.subtle) and the copy buttons need a secure context
cat <<'EOF' >/etc/nginx/sites-available/chartdb
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    http2 on;
    server_name _;

    ssl_certificate /etc/ssl/chartdb/chartdb.crt;
    ssl_certificate_key /etc/ssl/chartdb/chartdb.key;

    root /opt/chartdb/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location = /config.js {
        alias /opt/chartdb_data/config.js;
        add_header Cache-Control "no-cache";
    }
}
EOF
nginx_enable_site "chartdb"
msg_ok "Configured ChartDB"

motd_ssh
customize
cleanup_lxc
