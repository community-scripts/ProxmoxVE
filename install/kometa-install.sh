#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Kometa-Team/Kometa

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
    sudo
msg_ok "Installed Dependencies"

msg_info "Setup Python 3"
$STD apt-get install python3-pip -y
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Setup Python 3"

msg_info "Setup Kometa"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/Kometa-Team/Kometa/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/Kometa-Team/Kometa/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
tar -xzf "$temp_file"
mv Kometa-${RELEASE} /opt/kometa
cd /opt/kometa
$STD pip install -r requirements.txt --ignore-installed
mkdir -p config/assets
cp config/config.yml.template config/config.yml
echo "${RELEASE}" >/opt/kometa_version.txt
msg_ok "Setup Kometa"

read -p "Enter your TMDb API key: " TMDBKEY
read -p "Enter your Plex URL: " PLEXURL
read -p "Enter your Plex token: " PLEXTOKEN
sed -i -e "s#url: http://192.168.1.12:32400#url: $PLEXURL#g" /opt/kometa/config/config.yml
sed -i -e "s/token: ####################/token: $PLEXTOKEN/g" /opt/kometa/config/config.yml
sed -i -e "s/apikey: ################################/apikey: $TMDBKEY/g" /opt/kometa/config/config.yml

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/kometa.service
[Unit]
Description=Kometa Service
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/kometa
ExecStart=/usr/bin/python3 kometa.py
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q kometa
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
