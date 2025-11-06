#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kavitareader.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "Kavita" "Kareadita/Kavita" "prebuild" "latest" "/opt/Kavita" "kavita-linux-x64.tar.gz"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/kavita.service
[Unit]
Description=Kavita Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/Kavita
ExecStart=/opt/Kavita/Kavita
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
chmod +x /opt/Kavita/Kavita && chown root:root /opt/Kavita/Kavita
systemctl enable -q --now kavita
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
