#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: William Lindholm (LindholmLabs)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.factorio.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_from_url "https://factorio.com/get-download/stable/headless/$(arch_resolve "linux64" "linux-arm64")" "/opt/factorio"

msg_info "Configuring Factorio"
sed 's/"public":[[:space:]]*true/"public": false/' /opt/factorio/data/server-settings.example.json >/opt/factorio/server-settings.json
cat <<EOF >/opt/factorio/server-adminlist.json
[]
EOF
msg_ok "Configured Factorio"

msg_info "Creating Factorio Save"
mkdir -p /opt/factorio/saves
$STD /opt/factorio/bin/$(arch_resolve "x64" "arm64")/factorio --create /opt/factorio/saves/save.zip
msg_ok "Created Factorio Save"

msg_info "Creating Factorio Service"
cat <<EOF >/etc/systemd/system/factorio.service
[Unit]
Description=Factorio Headless Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/factorio
ExecStart=/opt/factorio/bin/$(arch_resolve "x64" "arm64")/factorio --start-server-load-latest --server-settings /opt/factorio/server-settings.json --server-adminlist /opt/factorio/server-adminlist.json
KillSignal=SIGINT
TimeoutStopSec=120
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now factorio

msg_ok "Created Factorio Service"

motd_ssh
customize
cleanup_lxc
