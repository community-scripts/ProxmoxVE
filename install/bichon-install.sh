#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustmailer/bichon

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "bichon" "rustmailer/bichon" "prebuild" "latest" "/opt/bichon" "bichon-*-x86_64-unknown-linux-gnu.tar.gz"

read -r -p "${TAB3}Enter the public URL for Bichon (e.g., https://bichon.yourdomain.com) or leave empty to use container IP: " bichon_url
if [[ -z "$bichon_url" ]]; then
  msg_info "No URL provided"
  BICHON_PUBLIC_URL="http://$LOCAL_IP:15630"
  msg_ok "Using local IP: http://$LOCAL_IP:15630\n"
else
  msg_info "URL provided"
  BICHON_PUBLIC_URL="$bichon_url"
  msg_ok "Using provided URL: $BICHON_PUBLIC_URL\n"
fi

msg_info "Setting up Bichon"
mkdir -p /opt/bichon-data
BICHON_ENC_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

cat <<EOF >/opt/bichon/bichon.env
BICHON_ROOT_DIR=/opt/bichon-data
BICHON_LOG_LEVEL=info
BICHON_ENCRYPT_PASSWORD=$BICHON_ENC_PASSWORD
BICHON_PUBLIC_URL=$BICHON_PUBLIC_URL
BICHON_CORS_ORIGINS=$BICHON_PUBLIC_URL
EOF
msg_ok "Setup Bichon"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bichon.service
[Unit]
Description=Bichon service
After=network.target

[Service]
Type=simple
User=root
EnvironmentFile=/opt/bichon/bichon.env
WorkingDirectory=/opt/bichon
ExecStart=/opt/bichon/bichon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bichon
msg_info "Created Service"

motd_ssh
customize
cleanup_lxc
