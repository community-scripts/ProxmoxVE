#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: doge0420
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lyqht/mini-qr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libharfbuzz0b \
  caddy \
  fontconfig
msg_ok "Installed Dependencies"

NODE_VERSION="20" setup_nodejs
fetch_and_deploy_gh_release "mini-qr" "lyqht/mini-qr" "tarball"

msg_info "Building MiniQR"
cd /opt/mini-qr
$STD npm install
$STD npm run build
msg_ok "Built MiniQR"

msg_info "Configuring Caddy"
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/mini-qr/dist
    file_server

    # Handle client-side routing
    try_files {path} /index.html

    # Cache static assets
    @assets {
        path /assets/*
    }
    header @assets Cache-Control "public, immutable, max-age=31536000"

    # Correct MIME types for JS modules
    @jsmodules {
        path *.js *.mjs
    }
    header @jsmodules Content-Type "application/javascript"
}
EOF
systemctl enable -q --now caddy
systemctl reload caddy
msg_ok "Configured Caddy"

motd_ssh
customize
cleanup_lxc
