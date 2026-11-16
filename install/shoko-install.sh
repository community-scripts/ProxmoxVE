#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ShokoAnime/ShokoServer

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  mediainfo \
  "$(apt-cache show librhash1 &>/dev/null && echo librhash1 || echo librhash0)"
msg_ok "Installed Dependencies"

DOTNET_VERSION="8" DOTNET_TYPE="aspnetcore" setup_dotnet

fetch_and_deploy_gh_release "shoko" "ShokoAnime/ShokoServer" "prebuild" "latest" "/opt/shoko" "Shoko.CLI_Framework_any-x64.zip"

msg_info "Creating Service"
mkdir -p /opt/shoko_data
chmod +x /opt/shoko/Shoko.CLI
cat <<EOF >/etc/systemd/system/shoko.service
[Unit]
Description=Shoko Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/shoko
Environment=HOME=/opt/shoko_data
Environment=DOTNET_CLI_TELEMETRY_OPTOUT=1
ExecStart=/opt/shoko/Shoko.CLI
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now shoko
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
