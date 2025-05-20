#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rclone/rclone

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  apache2-utils \
  unzip
msg_ok "Installed Dependencies"

msg_info "Installing rclone"
temp_file=$(mktemp)
mkdir -p /opt/rclone
RELEASE=$(curl -s https://api.github.com/repos/rclone/rclone/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/rclone/rclone/releases/download/v${RELEASE}/rclone-v${RELEASE}-linux-amd64.zip" -o "$temp_file"
$STD unzip -j "$temp_file" '*/**' -d /opt/rclone
cd /opt/rclone
RCLONE_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD htpasswd -cb -B /opt/login.pwd admin "$RCLONE_PASSWORD"
{
  echo "rclone-Credentials"
  echo "rclone User Name: admin"
  echo "rclone Password: $RCLONE_PASSWORD"
} >>~/rclone.creds
echo "${RELEASE}" >/opt/rclone_version.txt
msg_ok "Installed rclone"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/rclone-web.service
[Unit]
Description=Rclone Web GUI
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/rclone
ExecStart=/opt/rclone/rclone rcd --rc-web-gui --rc-web-gui-no-open-browser --rc-addr :3000 --rc-htpasswd /opt/login.pwd
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now rclone-web
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
