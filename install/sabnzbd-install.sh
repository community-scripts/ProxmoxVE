#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sabnzbd.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    par2 \
    p7zip-full
msg_ok "Installed Dependencies"

msg_info "Setup uv"
setup_uv
msg_ok "Setup uv"

msg_info "Setup Unrar"
cat <<EOF >/etc/apt/sources.list.d/non-free.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
EOF
$STD apt-get update
$STD apt-get install -y unrar
rm /etc/apt/sources.list.d/non-free.list
msg_ok "Setup Unrar"

msg_info "Installing SABnzbd"
RELEASE=$(curl -fsSL https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
mkdir -p /opt/sabnzbd
$STD uv venv /opt/sabnzbd/venv
temp_file=$(mktemp)
curl -fsSL "https://github.com/sabnzbd/sabnzbd/releases/download/${RELEASE}/SABnzbd-${RELEASE}-src.tar.gz" -o "$temp_file"
tar -xzf "$temp_file" -C /opt/sabnzbd --strip-components=1
$STD uv pip install -r /opt/sabnzbd/requirements.txt --python=/opt/sabnzbd/venv/bin/python
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed SABnzbd"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/sabnzbd.service
[Unit]
Description=SABnzbd
After=network.target

[Service]
WorkingDirectory=/opt/sabnzbd
ExecStart=/opt/sabnzbd/venv/bin/python SABnzbd.py -s 0.0.0.0:7777
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sabnzbd
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
