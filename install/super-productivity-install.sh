#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://super-productivity.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "super-productivity" "super-productivity/super-productivity" "tarball"

msg_info "Building Web App"
cd /opt/super-productivity
export HUSKY=0
export UNSPLASH_KEY=DUMMY_UNSPLASH_KEY
export UNSPLASH_CLIENT_ID=DUMMY_UNSPLASH_CLIENT_ID
export NODE_OPTIONS="--max-old-space-size=4096"
$STD git config --global url."https://github.com/".insteadOf ssh://git@github.com/
$STD npm ci
$STD npm run buildFrontend:prodWeb
msg_ok "Built Web App"

msg_info "Deploying Web App"
cp -r /opt/super-productivity/dist/browser/. /var/www/html/
msg_ok "Deployed Web App"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/super-productivity.conf
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
ln -sf /etc/nginx/sites-available/super-productivity.conf /etc/nginx/sites-enabled/super-productivity.conf
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
