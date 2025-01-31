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

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Autobrr"
wget -q $(curl -s https://api.github.com/repos/autobrr/autobrr/releases/latest | grep download | grep linux_x86_64 | cut -d\" -f4)
tar -C /usr/local/bin -xzf autobrr*.tar.gz
rm -rf autobrr*.tar.gz
mkdir -p /root/.config/autobrr
cat <<EOF >>/root/.config/autobrr/config.toml
# https://autobrr.com/configuration/autobrr
host = "0.0.0.0"
port = 7474
logLevel = "DEBUG"
sessionSecret = "$(openssl rand -base64 24)"
EOF
msg_ok "Installed Autobrr"

msg_info "Creating Service"
service_path="/etc/systemd/system/autobrr.service"
echo "[Unit]
Description=autobrr service
After=syslog.target network-online.target
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/autobrr --config=/root/.config/autobrr/
[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable --now -q autobrr.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
