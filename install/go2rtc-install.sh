#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
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
setup_hwaccel

USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "go2rtc" "AlexxIT/go2rtc" "singlefile" "latest" "/opt/go2rtc" "go2rtc_linux_amd64"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/go2rtc.service
echo "[Unit]
Description=go2rtc service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/go2rtc
ExecStart=/opt/go2rtc/go2rtc_linux_amd64

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now go2rtc
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
