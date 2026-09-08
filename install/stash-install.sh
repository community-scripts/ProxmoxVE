#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/stashapp/stash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_ffmpeg
setup_hwaccel

fetch_and_deploy_gh_release "stash" "stashapp/stash" "singlefile" "latest" "/opt/stash" "$(arch_resolve stash-linux stash-linux-arm64v8)"

msg_info "Creating Service"
mkdir -p /opt/stash_data
cat <<EOF >/etc/systemd/system/stash.service
[Unit]
Description=Stash
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/stash
Environment=STASH_CONFIG_FILE=/opt/stash_data/config.yml
ExecStart=/opt/stash/stash
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now stash
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
