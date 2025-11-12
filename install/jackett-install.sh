#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Jackett/Jackett

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "jackett" "Jackett/Jackett" "prebuild" "latest" "/opt/Jackett" "Jackett.Binaries.LinuxAMDx64.tar.gz"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/jackett.service
[Unit]
Description=Jackett Daemon
After=network.target

[Service]
SyslogIdentifier=jackett
Restart=always
RestartSec=5
Type=simple
WorkingDirectory=/opt/Jackett
ExecStart=/bin/sh /opt/Jackett/jackett_launcher.sh
TimeoutStopSec=30
EnvironmentFile="/opt/.env"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now jackett
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
