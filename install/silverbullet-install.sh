#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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

RELEASE=$(curl -s https://api.github.com/repos/silverbulletmd/silverbullet/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

msg_info "Installing ${APPLICATION}"
mkdir -p /opt/silverbullet/bin /opt/silverbullet/space
wget -q https://github.com/silverbulletmd/silverbullet/releases/download/${RELEASE}/silverbullet-server-linux-x86_64.zip
unzip silverbullet-server-linux-x86_64.zip &>/dev/null
mv silverbullet /opt/silverbullet/bin/
chmod +x /opt/silverbullet/bin/silverbullet
ln -s /opt/silverbullet/bin/silverbullet /usr/local/bin/silverbullet
echo "${RELEASE}" >/opt/silverbullet/${APPLICATION}_version.txt
msg_ok "Installed ${APPLICATION}"

msg_info "Creating Service"
service_path="/etc/systemd/system/silverbullet.service"

echo "[Unit]
Description=Silverbullet Daemon
After=syslog.target network.target

[Service]
User=root
Type=simple
ExecStart=/opt/silverbullet/bin/silverbullet --hostname 0.0.0.0 --port 3000 /opt/silverbullet/space
WorkingDirectory=/opt/silverbullet
Restart=on-failure

[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable --now -q silverbullet
msg_ok "Created Service"

msg_info "Starting ${APPLICATION}"
systemctl start silverbullet.service
sleep 1
if systemctl status silverbullet.service &>/dev/null ; then
	msg_ok "Started ${APPLICATION}"
else
	msg_error "Failed to start ${APPLICATION}"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm silverbullet-server-linux-x86_64.zip
msg_ok "Cleaned"
