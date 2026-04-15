#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pfassina
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/androidseb25/iGotify-Notification-Assistent

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  "https://packages.microsoft.com/debian/13/prod/" \
  "trixie" \
  "main"
$STD apt install -y aspnetcore-runtime-10.0
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "igotify" "androidseb25/iGotify-Notification-Assistent" "prebuild" "latest" "/opt/igotify" "iGotify-Notification-Service-amd64-v*.zip"

msg_info "Creating Service"
cat <<EOF >/opt/igotify/.env
ASPNETCORE_URLS=http://0.0.0.0:80
ASPNETCORE_ENVIRONMENT=Production
GOTIFY_DEFAULTUSER_PASS=
GOTIFY_URLS=
GOTIFY_CLIENT_TOKENS=
SECNTFY_TOKENS=
EOF
cat <<EOF >/etc/systemd/system/igotify.service
[Unit]
Description=iGotify Notification Service
After=network.target

[Service]
EnvironmentFile=/opt/igotify/.env
WorkingDirectory=/opt/igotify
ExecStart=/usr/bin/dotnet "/opt/igotify/iGotify Notification Assist.dll"
Restart=always
RestartSec=10
KillSignal=SIGINT
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now igotify
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
