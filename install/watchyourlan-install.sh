#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/aceberg/WatchYourLAN

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  arp-scan \
  ieee-data \
  libwww-perl
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "watchyourlan" "aceberg/WatchYourLAN" "binary"

msg_info "Configuring WatchYourLAN"
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
msg_ok "Configured WatchYourLAN"

msg_info "Creating Service"
sed -i 's|/etc/watchyourlan/config.yaml|/data/config.yaml|' /lib/systemd/system/watchyourlan.service
systemctl enable -q --now watchyourlan
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
