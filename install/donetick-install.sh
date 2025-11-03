#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: fstof
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/donetick/donetick

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y ca-certificates
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "donetick" "donetick/donetick" "prebuild" "latest" "/opt/donetick" "donetick_Linux_x86_64.tar.gz"

msg_info "Setup Donetick"
cd /opt/donetick
TOKEN=$(openssl rand -hex 16)
sed -i -e "s/change_this_to_a_secure_random_string_32_characters_long/${TOKEN}/g" config/selfhosted.yaml
msg_ok "Setup Donetick"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/donetick.service
[Unit]
Description=donetick Service
After=network.target

[Service]
Environment="DT_ENV=selfhosted"
WorkingDirectory=/opt/donetick
ExecStart=/opt/donetick/donetick
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now donetick
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"

