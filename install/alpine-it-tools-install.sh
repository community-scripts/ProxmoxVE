#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: nicedevil007 (NiceDevil)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://it-tools.tech/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add \
  curl \
  mc \
  openssh \
  nginx \
  unzip
msg_ok "Installed Dependencies"

msg_info "Installing IT-Tools"
RELEASE=$(curl -s https://api.github.com/repos/CorentinTh/it-tools/releases/latest | grep '"tag_name":' | cut -d '"' -f4)
DOWNLOAD_URL="https://github.com/CorentinTh/it-tools/releases/download/${RELEASE}/it-tools-${RELEASE#v}.zip"

curl -fsSL -o it-tools.zip "$DOWNLOAD_URL"
mkdir -p /usr/share/nginx/html
unzip -q it-tools.zip -d /tmp/it-tools
cp -r /tmp/it-tools/dist/* /usr/share/nginx/html
cat <<'EOF' > /etc/nginx/http.d/default.conf
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
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed IT-Tools"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/it-tools
rm -f it-tools.zip
$STD apk cache clean
msg_ok "Cleaned"
