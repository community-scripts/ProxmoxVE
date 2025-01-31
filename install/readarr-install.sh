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
msg_ok "Installed Dependencies"

msg_info "Installing Readarr"
mkdir -p /var/lib/readarr/
chmod 775 /var/lib/readarr/
$STD wget --content-disposition 'https://readarr.servarr.com/v1/update/develop/updatefile?os=linux&runtime=netcore&arch=x64'
$STD tar -xvzf Readarr.develop.*.tar.gz
mv Readarr /opt
chmod 775 /opt/Readarr
msg_ok "Installed Readarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/readarr.service
[Unit]
Description=Readarr Daemon
After=syslog.target network.target
[Service]
UMask=0002
Type=simple
ExecStart=/opt/Readarr/Readarr -nobrowser -data=/var/lib/readarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl -q daemon-reload
systemctl enable --now -q readarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf Readarr.develop.*.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
