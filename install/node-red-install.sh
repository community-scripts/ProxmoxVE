#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nodered.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

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
systemctl enable -q --now nodered
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
