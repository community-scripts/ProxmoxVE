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
$STD apt install -y apache2-utils fuse3
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "rclone" "rclone/rclone" "prebuild" "latest" "/opt/rclone" "rclone*linux-amd64.zip"

msg_info "Installing rclone"
cd /opt/rclone
RCLONE_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD htpasswd -cb -B /opt/login.pwd admin "$RCLONE_PASSWORD"
{
  echo "rclone-Credentials"
  echo "rclone User Name: admin"
  echo "rclone Password: $RCLONE_PASSWORD"
} >>~/rclone.creds
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
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
