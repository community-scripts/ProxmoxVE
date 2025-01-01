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
$STD apt-get install -y python3-libtorrent
msg_ok "Installed Dependencies"

msg_info "Updating Python3"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Updated Python3"

msg_info "Installing Deluge"
$STD pip install deluge[all]
msg_ok "Installed Deluge"

msg_info "Creating Service"
service_path="/etc/systemd/system/deluged.service"
echo "[Unit]
Description=Deluge Bittorrent Client Daemon
Documentation=man:deluged
After=network-online.target

[Service]
Type=simple
UMask=007
ExecStart=/usr/local/bin/deluged -d
Restart=on-failure
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target" >$service_path

service_path="/etc/systemd/system/deluge-web.service"
echo "[Unit]
Description=Deluge Bittorrent Client Web Interface
Documentation=man:deluge-web
After=deluged.service
Wants=deluged.service

[Service]
Type=simple
UMask=027
ExecStart=/usr/local/bin/deluge-web -d
Restart=on-failure

[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable --now -q deluged.service
systemctl enable --now -q deluge-web.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
