#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Listenarrs/Listenarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y libicu-dev
msg_ok "Installed Dependencies"

GH_INCLUDE_PRERELEASE=1 fetch_and_deploy_gh_release "listenarr" "Listenarrs/Listenarr" "prebuild" "latest" "/opt/listenarr" "listenarr-*-linux-x64.zip"

msg_info "Configuring Listenarr"
mkdir -p /opt/listenarr_data
ln -s /opt/listenarr/wwwroot /opt/listenarr_data/wwwroot
msg_ok "Configured Listenarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/listenarr.service
[Unit]
Description=Listenarr
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/listenarr
Environment=LISTENARR_CONTENT_ROOT=/opt/listenarr_data
ExecStart=/opt/listenarr/Listenarr.Api
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now listenarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
