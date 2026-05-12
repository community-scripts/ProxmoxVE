#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "kometa" "Kometa-Team/Kometa" "tarball"

msg_info "Setup Kometa"
cd /opt/kometa
$STD uv pip install -r requirements.txt --system
mkdir -p config/assets
cp config/config.yml.template config/config.yml
msg_ok "Setup Kometa"

read -r -p "${TAB3}Enter your TMDb API key: " TMDBKEY
read -r -p "${TAB3}Enter your Plex URL: " PLEXURL
read -r -p "${TAB3}Enter your Plex token: " PLEXTOKEN
sed -i '/^plex:/,/^[^ ]/{s|  url:.*|  url: '"$PLEXURL"'|}' /opt/kometa/config/config.yml
sed -i '/^plex:/,/^[^ ]/{s|  token:.*|  token: '"$PLEXTOKEN"'|}' /opt/kometa/config/config.yml
sed -i '/^tmdb:/,/^[^ ]/{s|  apikey:.*|  apikey: '"$TMDBKEY"'|}' /opt/kometa/config/config.yml

fetch_and_deploy_gh_release "kometa-quickstart" "Kometa-Team/Quickstart" "tarball"

msg_info "Installing Kometa Quickstart"
cd /opt/kometa-quickstart
$STD uv venv /opt/kometa-quickstart/.venv
$STD uv pip install -r requirements.txt -p /opt/kometa-quickstart/.venv/bin/python
msg_ok "Installed Kometa Quickstart"

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
cat <<EOF >/etc/systemd/system/kometa-quickstart.service
[Unit]
Description=Kometa Quickstart
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/kometa-quickstart
ExecStart=/opt/kometa-quickstart/.venv/bin/python quickstart.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kometa kometa-quickstart
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
