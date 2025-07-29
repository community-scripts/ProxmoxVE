#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sysadminsmedia/homebox

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "homebox" "sysadminsmedia/homebox" "prebuild" "latest" "/opt/homebox" "homebox_Linux_x86_64.tar.gz"

msg_info "Configuring Homebox"
chmod +x /opt/homebox/homebox
cat <<EOF >/opt/homebox/.env
# For possible environment variables check here: https://homebox.software/en/configure-homebox
HBOX_MODE=production
HBOX_WEB_PORT=7745
HBOX_WEB_HOST=0.0.0.0
EOF
msg_ok "Configured Homebox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homebox.service
[Unit]
Description=Start Homebox Service
After=network.target

[Service]
WorkingDirectory=/opt/homebox
ExecStart=/opt/homebox/homebox
EnvironmentFile=/opt/homebox/.env
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homebox
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
