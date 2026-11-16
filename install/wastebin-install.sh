#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matze/wastebin

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y zstd
msg_ok "Installed dependencies"

fetch_and_deploy_gh_release "wastebin" "matze/wastebin" "prebuild" "latest" "/opt/wastebin" "wastebin_*_$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl.tar.zst"
chmod +x /opt/wastebin/wastebin /opt/wastebin/wastebin-ctl

msg_info "Configuring Wastebin"

mkdir -p /opt/wastebin-data
cat <<EOF >/opt/wastebin-data/.env
WASTEBIN_DATABASE_PATH=/opt/wastebin-data/wastebin.db
WASTEBIN_CACHE_SIZE=1024
WASTEBIN_HTTP_TIMEOUT=30
WASTEBIN_SIGNING_KEY=$(openssl rand -hex 32)
WASTEBIN_PASTE_EXPIRATIONS=0,600,3600=d,86400,604800,2419200,29030400
EOF
msg_ok "Configured Wastebin"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wastebin.service
[Unit]
Description=Start Wastebin Service
After=network.target

[Service]
WorkingDirectory=/opt/wastebin
ExecStart=/opt/wastebin/wastebin
EnvironmentFile=/opt/wastebin-data/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wastebin
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
