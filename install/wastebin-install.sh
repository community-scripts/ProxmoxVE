#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matze/wastebin

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

msg_info "Installing Wastebin"
RELEASE=$(curl -s https://api.github.com/repos/matze/wastebin/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q https://github.com/matze/wastebin/releases/download/${RELEASE}/wastebin_${RELEASE}_x86_64-unknown-linux-musl.tar.zst
tar -xf wastebin_${RELEASE}_x86_64-unknown-linux-musl.tar.zst
rm -rf wastebin_${RELEASE}_x86_64-unknown-linux-musl.tar.zst
mkdir -p /opt/wastebin
mv wastebin /opt/wastebin/
chmod +x /opt/wastebin/wastebin
msg_ok "Installed Wastebin"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wastebin.service
[Unit]
Description=Start Wastebin Service
After=network.target

[Service]
WorkingDirectory=/opt/wastebin
ExecStart=/opt/wastebin/wastebin

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wastebin.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
