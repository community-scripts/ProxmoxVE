#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ombi.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "ombi" "Ombi-app/Ombi" "prebuild" "latest" "/opt/ombi" "linux-x64.tar.gz"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ombi.service
[Unit]
Description=Ombi
After=syslog.target network-online.target

[Service]
ExecStart=/opt/ombi/./Ombi
WorkingDirectory=/opt/ombi
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ombi
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
