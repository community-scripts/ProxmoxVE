#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: elvito
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PCJones/UmlautAdaptarr

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
  "https://packages.microsoft.com/keys/microsoft.asc" \
  "https://packages.microsoft.com/debian/12/prod/" \
  "bookworm" \
  "main"
$STD apt install -y \
  dotnet-sdk-8.0 \
  aspnetcore-runtime-8.0
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "UmlautAdaptarr" "PCJones/Umlautadaptarr" "prebuild" "latest" "/opt/UmlautAdaptarr" "linux-x64.zip"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/umlautadaptarr.service
[Unit]
Description=UmlautAdaptarr Service
After=network.target

[Service]
WorkingDirectory=/opt/UmlautAdaptarr
ExecStart=/usr/bin/dotnet /opt/UmlautAdaptarr/UmlautAdaptarr.dll --urls=http://0.0.0.0:5005
Restart=always
User=root
Group=root
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now umlautadaptarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
