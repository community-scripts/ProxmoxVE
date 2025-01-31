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
$STD apt-get install -y {curl,sudo,mc,gpg,arp-scan,ieee-data,libwww-perl}
msg_ok "Installed Dependencies"

msg_info "Installing WatchYourLAN"
RELEASE=$(curl -s https://api.github.com/repos/aceberg/WatchYourLAN/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d '"' -f 4)
wget -q https://github.com/aceberg/WatchYourLAN/releases/download/$RELEASE/watchyourlan_${RELEASE}_linux_amd64.deb
$STD dpkg -i watchyourlan_${RELEASE}_linux_amd64.deb
rm watchyourlan_${RELEASE}_linux_amd64.deb
mkdir /data
cat <<EOF >/data/config.yaml
arp_timeout: "500"
auth: false
auth_expire: 7d
auth_password: ""
auth_user: ""
color: dark
dbpath: /data/db.sqlite
guiip: 0.0.0.0
guiport: "8840"
history_days: "30"
iface: eth0
ignoreip: "no"
loglevel: verbose
shoutrrr_url: ""
theme: solar
timeout: 60
EOF
msg_ok "Installed WatchYourLAN"

msg_info "Creating Service"
sed -i 's|/etc/watchyourlan/config.yaml|/data/config.yaml|' /lib/systemd/system/watchyourlan.service
systemctl enable -q --now watchyourlan.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
