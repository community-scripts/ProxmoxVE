#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Whisparr/Whisparr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y sqlite3
msg_ok "Installed Dependencies"

fetch_and_deploy_from_url "https://whisparr.servarr.com/v1/update/nightly/updatefile?os=linux&runtime=netcore&arch=x64" /opt/Whisparr

msg_info "Configuring Whisparr"
mkdir -p /var/lib/whisparr/
chmod 775 /var/lib/whisparr/
chmod 775 /opt/Whisparr
msg_ok "Configured Whisparr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/whisparr.service
[Unit]
Description=whisparr Daemon
After=syslog.target network.target

[Service]
UMask=0002
Type=simple
ExecStart=/opt/Whisparr/Whisparr -nobrowser -data=/var/lib/whisparr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now whisparr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
