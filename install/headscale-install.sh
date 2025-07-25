#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/juanfont/headscale

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "headscale" "juanfont/headscale" "binary"

read -r -p "${TAB3}Would you like to add headscale-admin UI? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  fetch_and_deploy_gh_release "headscale-admin" "GoodiesHQ/headscale-admin" "prebuild" "latest" "/opt/headscale-admin" "admin.zip"
  
  msg_info "Configuring headscale-admin"
  $STD apt-get install -y caddy
  $STD caddy stop
  rm /etc/caddy/Caddyfile
  cat <<'EOF' >/etc/caddy/Caddyfile
:{$PORT:80}

handle_path /admin* {
        root * /opt/headscale-admin
        encode gzip zstd

        # Correct MIME types for JS/WASM
        header {
                @js_files path *.js
                @wasm_files path *.wasm

                Content-Type @js_files application/javascript
                Content-Type @wasm_files application/wasm

                X-Content-Type-Options nosniff
        }

        # Fallback for SPA routing
        try_files {path} {path}/ index.html
        file_server
}

EOF
  caddy fmt --overwrite /etc/caddy/Caddyfile
  systemctl start caddy
  msg_ok "Configured headscale-admin"
fi

msg_info "Starting service"
systemctl enable -q --now headscale
msg_ok "Service started"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
