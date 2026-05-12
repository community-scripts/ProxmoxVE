#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: John Lombardo
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thelastoutpostworkshop/ESPConnect

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

fetch_and_deploy_gh_release "espconnect" "thelastoutpostworkshop/ESPConnect" "prebuild" "latest" "/opt/espconnect" "dist.zip"

msg_info "Configuring Nginx"
mkdir -p /etc/ssl/private
$STD openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
  -keyout /etc/ssl/private/espconnect-selfsigned.key \
  -out /etc/ssl/certs/espconnect-selfsigned.crt \
  -subj "/CN=ESPConnect"

cat <<'EOF' >/etc/nginx/sites-available/espconnect
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    ssl_certificate /etc/ssl/certs/espconnect-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/espconnect-selfsigned.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /opt/espconnect;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
ln -sf /etc/nginx/sites-available/espconnect /etc/nginx/sites-enabled/espconnect
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
systemctl enable -q nginx
systemctl restart nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
