#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: nicedevil007 (NiceDevil)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://it-tools.tech/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add --no-cache \
  nginx \
  python3
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "it-tools" "sharevb/it-tools" "prebuild" "latest" "/usr/share/nginx/html" "it-tools-*.zip"

msg_info "Configuring IT-Tools"
cat <<'EOF' >/etc/nginx/http.d/default.conf
server {
  listen 80;
  server_name localhost;
  root /usr/share/nginx/html;
  index index.html;
  
  location / {
      try_files $uri $uri/ /index.html;
  }
}
EOF
$STD rc-update add nginx default
$STD rc-service nginx start
msg_ok "Configured IT-Tools"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/dist
rm -f it-tools.zip
$STD apk cache clean
msg_ok "Cleaned"
