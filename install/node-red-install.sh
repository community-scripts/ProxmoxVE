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
$STD apt-get install -y git
$STD apt-get install -y ca-certificates
$STD apt-get install -y gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing Node-Red"
$STD npm install -g --unsafe-perm node-red
echo "journalctl -f -n 100 -u nodered -o cat" >/usr/bin/node-red-log
chmod +x /usr/bin/node-red-log
echo "systemctl stop nodered" >/usr/bin/node-red-stop
chmod +x /usr/bin/node-red-stop
echo "systemctl start nodered" >/usr/bin/node-red-start
chmod +x /usr/bin/node-red-start
echo "systemctl restart nodered" >/usr/bin/node-red-restart
chmod +x /usr/bin/node-red-restart
msg_ok "Installed Node-Red"

msg_info "Creating Service"
service_path="/etc/systemd/system/nodered.service"
echo "[Unit]
Description=Node-RED
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/node-red --max-old-space-size=128 -v
Restart=on-failure
KillSignal=SIGINT

SyslogIdentifier=node-red
StandardOutput=syslog

WorkingDirectory=/root/
User=root
Group=root

[Install]
WantedBy=multi-user.target" >$service_path
$STD systemctl enable --now nodered.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
