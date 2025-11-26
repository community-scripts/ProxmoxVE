#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/qdrant/qdrant

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "qdrant" "qdrant/qdrant" "binary" "latest" "/usr/bin/qdrant"

msg_info "Creating Qdrant Configuration"
mkdir -p /var/lib/qdrant/storage
mkdir -p /var/lib/qdrant/snapshots
mkdir -p /etc/qdrant
chown -R root:root /var/lib/qdrant
chmod -R 755 /var/lib/qdrant

cat >/etc/qdrant/config.yaml <<EOF
log_level: INFO

storage:
  storage_path: /var/lib/qdrant/storage
  snapshots_path: /var/lib/qdrant/snapshots

service:
  host: 0.0.0.0
  http_port: 6333
  grpc_port: 6334
  enable_cors: true
EOF
msg_ok "Created Qdrant Configuration"

msg_info "Creating Qdrant Service"
cat >/etc/systemd/system/qdrant.service <<EOF
[Unit]
Description=Qdrant Vector Search Engine
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/qdrant --config-path /etc/qdrant/config.yaml
WorkingDirectory=/var/lib/qdrant
Restart=on-failure
RestartSec=5
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now qdrant
msg_ok "Created Qdrant Service"

motd_ssh
customize
cleanup_lxc
