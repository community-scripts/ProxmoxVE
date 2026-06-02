#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: reptil1990
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/qdm12/ddns-updater

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "ddns-updater" "qdm12/ddns-updater" "singlefile" "latest" "/opt/ddns-updater" "ddns-updater_*_linux_amd64"

msg_info "Configuring DDNS-Updater"
mkdir -p /opt/ddns-updater/data
cat <<EOF >/opt/ddns-updater/data/config.json
{
  "settings": [
    {
      "provider": "namecheap",
      "domain": "example.com",
      "password": "e5322165c1d74692bfa6d807100c0310"
    }
  ]
}
EOF
msg_ok "Configured DDNS-Updater"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ddns-updater.service
[Unit]
Description=DDNS-Updater
After=network.target

[Service]
Type=simple
ExecStart=/opt/ddns-updater/ddns-updater
Environment=DATADIR=/opt/ddns-updater/data
Environment=LISTENING_ADDRESS=:8000
Environment=LOG_LEVEL=info
Environment=PERIOD=5m
WorkingDirectory=/opt/ddns-updater
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ddns-updater
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
