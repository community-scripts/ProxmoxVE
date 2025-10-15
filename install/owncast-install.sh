#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://owncast.online/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt install -y ffmpeg
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "owncast" "owncast/owncast" "prebuild" "latest" "/opt/owncast" "owncast*linux-64bit.zip"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/owncast.service
[Unit]
Description=Owncast
After=syslog.target network-online.target

[Service]
ExecStart=/opt/owncast/./owncast
WorkingDirectory=/opt/owncast
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now owncast
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
