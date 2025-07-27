#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/AlexxIT/go2rtc

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "go2rtc" "AlexxIT/go2rtc" "singlefile" "latest" "/opt/go2rtc" "go2rtc_linux_amd64"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/go2rtc.service
echo "[Unit]
Description=go2rtc service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/go2rtc/go2rtc_linux_amd64

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now go2rtc
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
