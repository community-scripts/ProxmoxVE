#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pommee/goaway

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y net-tools
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "goaway" "pommee/goaway" "prebuild" "latest" "/opt/goaway" "goaway_*_linux_amd64.tar.gz"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/goaway.service
[Unit]
Description=GoAway Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/goaway
ExecStart=/opt/goaway/goaway
StandardOutput=file:/var/log/goaway.log
StandardError=inherit
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now goaway
sleep 10
for i in {1..30}; do
  ADMIN_PASS=$(awk -F': ' "/Randomly generated admin password:/ {print \$2; exit}" /var/log/goaway.log)
  [ -n "$ADMIN_PASS" ] && break
  sleep 1
done
{
  echo "GoAway Credentials"
  echo "Admin User: admin"
  echo "Admin Password: $ADMIN_PASS"
} >>~/goaway.creds
msg_ok "Service Created"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
