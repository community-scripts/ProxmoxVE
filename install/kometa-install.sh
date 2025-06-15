#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Kometa-Team/Kometa

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Kometa"
tmp_file=$(mktemp)
RELEASE=$(curl -fsSL https://api.github.com/repos/Kometa-Team/Kometa/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/Kometa-Team/Kometa/archive/refs/tags/v${RELEASE}.tar.gz" -o "$tmp_file"
tar -xzf "$tmp_file"
mv "Kometa-${RELEASE}" /opt/kometa
cd /opt/kometa
$STD uv venv /home/wger/.venv
$STD /opt/kometa/.venv/bin/python -m ensurepip --upgrade
$STD /opt/kometa/.venv/bin/python -m pip install --upgrade pip
$STD /opt/kometa/.venv/bin/python -m pip install -r requirements.txt
mkdir -p config/assets
cp config/config.yml.template config/config.yml
echo "$RELEASE" >/opt/kometa_version.txt
msg_ok "Installed Kometa"

read -p "${TAB3}Enter your TMDb API key: " TMDBKEY
read -p "${TAB3}Enter your Plex URL: " PLEXURL
read -p "${TAB3}Enter your Plex token: " PLEXTOKEN
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
ExecStart=/opt/kometa/.venv/bin/python kometa.py
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kometa
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$tmp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
