#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y ffmpeg
msg_ok "Installed Dependencies"

msg_info "Installing Owncast"
mkdir /opt/owncast
cd /opt/owncast
wget -q $(curl -s https://api.github.com/repos/owncast/owncast/releases/latest | grep download | grep linux-64bit | cut -d\" -f4)
$STD unzip owncast*.zip
rm owncast*.zip
msg_ok "Installed Owncast"

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
systemctl enable -q --now owncast.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
