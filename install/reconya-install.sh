#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dyneteq/reconya

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "reconya" "Dyneteq/reconya" "prebuild" "latest" "/opt/reconya" "reconya-linux-$(arch_resolve "amd64" "arm64").tar.gz"

msg_info "Configuring Reconya"
mkdir -p /opt/reconya_data
cat <<EOF >/opt/reconya_data/.env
PORT=3008
LOGIN_USERNAME=admin
LOGIN_PASSWORD=$(random_password)
DATABASE_NAME=reconya
SQLITE_PATH=/opt/reconya_data/reconya.db
PUBLIC_IP_LOOKUP_ENABLED=false
GEOLOCATION_ENABLED=false
VENDOR_LOOKUP_ONLINE_ENABLED=false
OUI_DOWNLOAD_ENABLED=false
EOF
chmod 600 /opt/reconya_data/.env
msg_ok "Configured Reconya"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/reconya.service
[Unit]
Description=Reconya
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/reconya_data
EnvironmentFile=/opt/reconya_data/.env
ExecStart=/opt/reconya/reconya-linux-$(arch_resolve "amd64" "arm64")
# Reconya ignores SIGTERM and only shuts down on SIGINT
KillSignal=SIGINT
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now reconya
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
