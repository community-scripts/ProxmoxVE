#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021 (Slaviša Arežina)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://teamspeak.com/en/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

RELEASE=$(curl -fsSL https://teamspeak.com/en/downloads/#server | grep -oP 'teamspeak3-server_linux_amd64-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)

msg_info "Setting up Teamspeak Server"
curl -fsSL "https://files.teamspeak-services.com/releases/server/${RELEASE}/teamspeak3-server_linux_amd64-${RELEASE}.tar.bz2" -o ts3server.tar.bz2
tar -xf ./ts3server.tar.bz2
mv teamspeak3-server_linux_amd64/ /opt/teamspeak-server/
touch /opt/teamspeak-server/.ts3server_license_accepted
echo "${RELEASE}" >~/.teamspeak-server
msg_ok "Setup Teamspeak Server"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/teamspeak-server.service
[Unit]
Description=TeamSpeak3 Server
Wants=network-online.target
After=network.target

[Service]
WorkingDirectory=/opt/teamspeak-server
User=root
Type=forking
ExecStart=/opt/teamspeak-server/ts3server_startscript.sh start
ExecStop=/opt/teamspeak-server/ts3server_startscript.sh stop
ExecReload=/opt/teamspeak-server/ts3server_startscript.sh restart
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now teamspeak-server
msg_ok "Created service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f ~/ts3server.tar.bz*
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
