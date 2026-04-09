#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alam00000/bentopdf

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os


msg_info "Installing Dependencies"
$STD apt install nginx -y
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "bentopdf" "alam00000/bentopdf" "tarball" "latest" "/opt/bentopdf"

msg_info "Setup BentoPDF"
cd /opt/bentopdf
$STD npm ci --no-audit --no-fund
cp ./.env.example ./.env.production
export NODE_OPTIONS="--max-old-space-size=3072"
export SIMPLE_MODE=true
export VITE_USE_CDN=true
$STD npm run build:all
msg_ok "Setup BentoPDF"

msg_info "Creating Service"
cat <<'EOF' >/etc/nginx/sites-available/bentopdf
server {
    listen 8080;
    server_name _;
    root /opt/bentopdf/dist;
    index index.html;

    # Required for LibreOffice WASM (Word/Excel/PowerPoint to PDF via SharedArrayBuffer)
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Embedder-Policy "require-corp" always;
    add_header Cross-Origin-Resource-Policy "cross-origin" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    gzip_static on;

    location / {
        try_files $uri $uri/ $uri.html =404;
    }

    error_page 404 /404.html;
}
EOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/bentopdf /etc/nginx/sites-enabled/bentopdf
cat <<'EOF' >/etc/systemd/system/bentopdf.service
[Unit]
Description=BentoPDF Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/nginx -g "daemon off;"
ExecReload=/bin/kill -HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now bentopdf
msg_ok "Created & started service"

motd_ssh
customize
cleanup_lxc
