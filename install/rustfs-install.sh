#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustfs/rustfs

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

mkdir -p /opt/rustfs_data/{data,logs}
fetch_and_deploy_gh_release "rustfs" "rustfs/rustfs" "prebuild" "latest" "/opt/rustfs" "rustfs-linux-$(arch_resolve x86_64 aarch64)-gnu-*.zip"
chmod +x /opt/rustfs/rustfs

msg_info "Configuring RustFS"
RUSTFS_ACCESS_KEY=$(openssl rand -hex 8)
RUSTFS_SECRET_KEY=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
cat <<EOF >/etc/default/rustfs
RUSTFS_ACCESS_KEY=${RUSTFS_ACCESS_KEY}
RUSTFS_SECRET_KEY=${RUSTFS_SECRET_KEY}
RUSTFS_VOLUMES=/opt/rustfs_data/data
RUSTFS_ADDRESS=:9000
RUSTFS_CONSOLE_ADDRESS=:9001
RUSTFS_CONSOLE_ENABLE=true
RUSTFS_OBS_LOGGER_LEVEL=error
RUSTFS_OBS_LOG_DIRECTORY=/opt/rustfs_data/logs/
EOF
chmod 600 /etc/default/rustfs
msg_ok "Configured RustFS"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/rustfs.service
[Unit]
Description=RustFS Object Storage
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/rustfs_data
EnvironmentFile=/etc/default/rustfs
ExecStart=/opt/rustfs/rustfs
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now rustfs
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
