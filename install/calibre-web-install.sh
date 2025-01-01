#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y imagemagick
msg_ok "Installed Dependencies"

msg_info "Installing Python Dependencies"
$STD apt-get -y install python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Installed Python Dependencies"

msg_info "Installing Kepubify"
mkdir -p /opt/kepubify
cd /opt/kepubify
curl -fsSLO https://github.com/pgaskin/kepubify/releases/latest/download/kepubify-linux-64bit &>/dev/null
chmod +x kepubify-linux-64bit
msg_ok "Installed Kepubify"

msg_info "Installing Calibre-Web"
mkdir -p /opt/calibre-web
$STD wget https://github.com/janeczku/calibre-web/raw/master/library/metadata.db -P /opt/calibre-web
$STD pip install calibreweb
$STD pip install jsonschema
msg_ok "Installed Calibre-Web"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cps.service
[Unit]
Description=Calibre-Web Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/calibre-web
ExecStart=/usr/local/bin/cps
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cps.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
