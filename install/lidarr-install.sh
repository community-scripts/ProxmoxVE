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
$STD apt-get install -y sqlite3
$STD apt-get install -y libchromaprint-tools
$STD apt-get install -y mediainfo
msg_ok "Installed Dependencies"

msg_info "Installing Lidarr"
mkdir -p /var/lib/lidarr/
chmod 775 /var/lib/lidarr/
$STD wget --content-disposition 'https://lidarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64'
$STD tar -xvzf Lidarr.master.*.tar.gz
mv Lidarr /opt
chmod 775 /opt/Lidarr
msg_ok "Installed Lidarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/lidarr.service
[Unit]
Description=Lidarr Daemon
After=syslog.target network.target
[Service]
UMask=0002
Type=simple
ExecStart=/opt/Lidarr/Lidarr -nobrowser -data=/var/lib/lidarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl -q daemon-reload
systemctl enable --now -q lidarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf Lidarr.master.*.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
