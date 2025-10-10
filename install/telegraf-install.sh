#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/influxdata/telegraf

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Adding Telegraf key and repository"
curl -fsSL -O https://repos.influxdata.com/influxdata-archive.key
gpg --show-keys --with-fingerprint --with-colons ./influxdata-archive.key 2>&1 |
  grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$' &&
  cat influxdata-archive.key |
  gpg --dearmor |
    tee /etc/apt/keyrings/influxdata-archive.gpg >/dev/null
cat <<EOF | sudo tee /etc/apt/sources.list.d/influxdata.sources >/dev/null
Types: deb
URIs: https://repos.influxdata.com/debian
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/influxdata-archive.gpg
EOF
msg_ok "Added Telegraf Repository"

msg_info "Installing Telegraf"
$STD apt update
$STD apt install telegraf -y
msg_ok "Installed Telegraf"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
rm /influxdata-archive.key
msg_ok "Cleaned"
