#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/steveiliop56/tinyauth

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  openssl \
  apache2-utils
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "tinyauth" "steveiliop56/tinyauth" "singlefile" "latest" "/opt/tinyauth" "tinyauth-amd64"

msg_info "Setting up Tinyauth"
PASS=$(openssl rand -base64 8 | tr -dc 'a-zA-Z0-9' | head -c 8)
USER=$(htpasswd -Bbn "tinyauth" "${PASS}")
cat <<EOF >/opt/tinyauth/credentials.txt
Tinyauth Credentials
Username: tinyauth
Password: ${PASS}
EOF
msg_ok "Set up Tinyauth"

read -r -p "${TAB3}Enter your Tinyauth subdomain (e.g. https://tinyauth.example.com): " app_url

msg_info "Creating Service"
cat <<EOF >/opt/tinyauth/.env
TINYAUTH_DATABASE_PATH=/opt/tinyauth/database.db
TINYAUTH_AUTH_USERS='${USER}'
TINYAUTH_APPURL=${app_url}
EOF
cat <<EOF >/etc/systemd/system/tinyauth.service
[Unit]
Description=Tinyauth Service
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/tinyauth/.env
ExecStart=/opt/tinyauth/tinyauth
WorkingDirectory=/opt/tinyauth
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tinyauth
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
