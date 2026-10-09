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

fetch_and_deploy_gh_release "ddns-updater" "qdm12/ddns-updater" "singlefile" "latest" "/opt/ddns-updater" "ddns-updater_*_linux_$(arch_resolve)"

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
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/bin/bash -c 'for i in \$(seq 1 30); do curl -sf --max-time 5 https://1.1.1.1 >/dev/null 2>&1 && break || sleep 2; done'
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
