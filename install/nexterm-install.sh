#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mathias Wagner (gnmyt)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://nexterm.dev/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "nexterm-engine" "gnmyt/Nexterm" "prebuild" "latest" "/opt/nexterm/engine" "nexterm-engine-linux-$(arch_resolve "x64" "arm64").tar.gz"
fetch_and_deploy_gh_release "nexterm-server" "gnmyt/Nexterm" "singlefile" "latest" "/opt/nexterm/server" "nexterm-server-linux-$(arch_resolve "x64" "arm64")"

msg_info "Configuring Nexterm"
LOCAL_ENGINE_TOKEN=$(tr -d '-' </proc/sys/kernel/random/uuid)$(tr -d '-' </proc/sys/kernel/random/uuid)
ENCRYPTION_KEY=$(tr -d '-' </proc/sys/kernel/random/uuid)$(tr -d '-' </proc/sys/kernel/random/uuid)
mkdir -p /etc/nexterm-engine /etc/nexterm-server /opt/nexterm/data
cat <<EOF >/etc/nexterm-engine/config.yaml
server_host: "127.0.0.1"
server_port: 7800
registration_token: "${LOCAL_ENGINE_TOKEN}"
tls: false
EOF
cat <<EOF >/etc/nexterm-server/server.env
NODE_ENV=production
SERVER_PORT=6989
LOCAL_ENGINE_TOKEN=${LOCAL_ENGINE_TOKEN}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
EOF
chmod 0640 /etc/nexterm-engine/config.yaml /etc/nexterm-server/server.env
msg_ok "Configured Nexterm"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/nexterm-server.service
[Unit]
Description=Nexterm Server
Documentation=https://docs.nexterm.dev/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nexterm/data
EnvironmentFile=/etc/nexterm-server/server.env
ExecStart=/opt/nexterm/server/nexterm-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/nexterm-engine.service
[Unit]
Description=Nexterm Engine
Documentation=https://docs.nexterm.dev/
After=network-online.target nexterm-server.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/nexterm-engine
Environment=FREERDP_EXTENSION_PATH=/opt/nexterm/engine/lib/freerdp2
Environment=LD_LIBRARY_PATH=/opt/nexterm/engine/lib
ExecStart=/opt/nexterm/engine/nexterm-engine
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nexterm-server
sleep 5
systemctl enable -q --now nexterm-engine
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
