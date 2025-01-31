#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Pocketbase"
RELEASE="$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')"
wget -q "https://github.com/pocketbase/pocketbase/releases/download/v${RELEASE}/pocketbase_${RELEASE}_linux_amd64.zip" -O /tmp/pocketbase.zip
mkdir -p /opt/pocketbase/{pb_public,pb_migrations,pb_hooks}
unzip -q -o /tmp/pocketbase.zip -d /opt/pocketbase

cat <<EOF >/etc/systemd/system/pocketbase.service
[Unit]
Description = pocketbase

[Service]
Type           = simple
LimitNOFILE    = 4096
Restart        = always
RestartSec     = 5s
StandardOutput = append:/opt/pocketbase/errors.log
StandardError  = append:/opt/pocketbase/errors.log
ExecStart      = /opt/pocketbase/pocketbase serve --http=0.0.0.0:8080

[Install]
WantedBy = multi-user.target
EOF

systemctl enable -q --now pocketbase.service
msg_ok "Installed Pocketbase"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/pocketbase.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
