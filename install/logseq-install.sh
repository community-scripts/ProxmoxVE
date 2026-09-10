#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://logseq.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  nginx \
  build-essential \
  libcairo2-dev \
  libpango1.0-dev \
  libjpeg-dev \
  libgif-dev \
  librsvg2-dev
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs
JAVA_VERSION="21" setup_java

msg_info "Installing Clojure CLI"
cd /tmp
curl_download "linux-install.sh" "https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh"
$STD bash linux-install.sh
rm -f linux-install.sh
msg_ok "Installed Clojure CLI"

fetch_and_deploy_gh_release "logseq" "logseq/logseq" "tarball"

msg_info "Building Logseq Web App (Patience)"
cd /opt/logseq
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export NODE_OPTIONS="--max-old-space-size=4096"
export JAVA_TOOL_OPTIONS="-Xmx4g"
$STD corepack enable
$STD pnpm install --config.network-timeout=240000
$STD pnpm release
msg_ok "Built Logseq Web App"

msg_info "Generating Self-Signed Certificate"
create_self_signed_cert "logseq"
msg_ok "Generated Self-Signed Certificate"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/logseq
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    http2 on;
    server_name _;

    ssl_certificate /etc/ssl/logseq/logseq.crt;
    ssl_certificate_key /etc/ssl/logseq/logseq.key;

    root /opt/logseq/static;
    index index.html;

    add_header Cross-Origin-Opener-Policy same-origin always;
    add_header Cross-Origin-Embedder-Policy require-corp always;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
nginx_enable_site logseq
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
