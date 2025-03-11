#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matze/wastebin

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    sudo \
    mc
msg_ok "Installed Dependencies"

msg_info "Installing Wastebin"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/matze/wastebin/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q https://github.com/matze/wastebin/releases/download/${RELEASE}/wastebin_${RELEASE}_x86_64-unknown-linux-musl.zip -O $temp_file
unzip -q $temp_file
mkdir -p /opt/wastebin
mv wastebin /opt/wastebin/
chmod +x /opt/wastebin/wastebin

mkdir -p /opt/wastebin-data
cat <<EOF >/opt/wastebin-data/.env
WASTEBIN_DATABASE_PATH=/opt/wastebin-data/wastebin.db
WASTEBIN_CACHE_SIZE=1024
WASTEBIN_HTTP_TIMEOUT=30
WASTEBIN_SIGNING_KEY=$(openssl rand -hex 32)
WASTEBIN_PASTE_EXPIRATIONS=0,600,3600=d,86400,604800,2419200,29030400
EOF
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"

msg_ok "Installed Wastebin"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wastebin.service
[Unit]
Description=Start Wastebin Service
After=network.target

[Service]
WorkingDirectory=/opt/wastebin
ExecStart=/opt/wastebin/wastebin
EnvironmentFile=/opt/wastebin-data/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wastebin
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
