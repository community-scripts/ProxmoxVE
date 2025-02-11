#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: Slaviša Arežina (tremor021)
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
$STD apt-get install -y \
    curl \
    mc \
    sudo \
    python3-pip
msg_ok "Installed Dependencies"

msg_info "Setup ssh-tarpit"
cd /tmp
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/Snawoot/ssh-tarpit/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/Snawoot/ssh-tarpit/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
tar -xzf "$temp_file"
mv ssh-tarpit-${RELEASE} /opt/ssh-tarpit
cd /opt/ssh-tarpit
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
$STD pip install .
echo "${RELEASE}" >/opt/ssh-tarpit_version.txt
msg_ok "Setup ssh-tarpit"

read -p "Enter port you wish to use: " PORT

msg_info "Creating Service"
cat << EOF >/etc/systemd/system/ssh-tarpit.service
[Unit]
Description=ssh-tarpit Service
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ssh-tarpit -a 0.0.0.0 -p $PORT
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q ssh-tarpit
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
