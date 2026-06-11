#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tobias Salzmann (Eun)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cinnyapp/cinny

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add --no-cache \
  jq \
  nginx
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "cinny" "cinnyapp/cinny" "prebuild" "latest" "/opt/cinny" "cinny-*.tar.gz"

msg_info "Configuring Cinny"
cat <<'EOF' >/etc/nginx/http.d/default.conf
server {
  listen 8080;
  server_name localhost;

  location / {
        root /opt/cinny;

        rewrite ^/config.json$ /config.json break;
        rewrite ^/manifest.json$ /manifest.json break;

        rewrite ^/sw.js$ /sw.js break;
        rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;

        rewrite ^/public/(.*)$ /public/$1 break;
        rewrite ^/assets/(.*)$ /assets/$1 break;

        rewrite ^(.+)$ /index.html break;
    }
}
EOF
$STD rc-update add nginx default
$STD rc-service nginx start
msg_ok "Configured Cinny"

motd_ssh
customize
cleanup_lxc
