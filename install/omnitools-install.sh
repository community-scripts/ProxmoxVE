#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Majiiin
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/iib0011/omni-tools

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
fetch_and_deploy_gh_release "omnitools" "iib0011/omni-tools" "tarball"

msg_info "Building OmniTools"
cd /opt/omnitools
export HUSKY=0
$STD npm ci
$STD npm run build
msg_ok "Built OmniTools"

msg_info "Publishing Web Assets"
rm -rf /usr/share/nginx/html
mkdir -p /usr/share/nginx/html
cp -a /opt/omnitools/dist/. /usr/share/nginx/html/
rm -rf /opt/omnitools/node_modules
msg_ok "Published Web Assets"

msg_info "Configuring Nginx"
sed -i \
  's/application\/javascript.*js;/application\/javascript                js mjs;/' \
  /etc/nginx/mime.types

cat <<'EOF' >/etc/nginx/sites-available/omnitools
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

nginx_enable_site omnitools
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
