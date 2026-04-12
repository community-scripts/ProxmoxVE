#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/seaweedfs/seaweedfs

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y fuse3
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "seaweedfs" "seaweedfs/seaweedfs" "prebuild" "latest" "/opt/seaweedfs" "linux_amd64.tar.gz"

msg_info "Setting up SeaweedFS"
mkdir -p /opt/seaweedfs-data
ln -sf /opt/seaweedfs/weed /usr/local/bin/weed
msg_ok "Set up SeaweedFS"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/seaweedfs.service
[Unit]
Description=SeaweedFS Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/seaweedfs
ExecStart=/opt/seaweedfs/weed server -dir=/opt/seaweedfs-data -master.port=9333 -volume.port=8080 -filer -s3
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seaweedfs
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
