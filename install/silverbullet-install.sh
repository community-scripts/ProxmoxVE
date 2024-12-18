#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: Dominik Siebel (dsiebel)
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
$STD apt-get install -y \
  curl \
  sudo \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Silverbullet"
RELEASE=$(curl -s https://api.github.com/repos/silverbulletmd/silverbullet/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
mkdir -p /opt/silverbullet/bin /opt/silverbullet/space
wget -q https://github.com/silverbulletmd/silverbullet/releases/download/${RELEASE}/silverbullet-server-linux-x86_64.zip
unzip -oq -d /opt/silverbullet/bin/ silverbullet-server-linux-x86_64.zip
chmod +x /opt/silverbullet/bin/silverbullet
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Silverbullet"

msg_info "Creating Service"

cat <<EOF >/etc/systemd/system/silverbullet.service
[Unit]
Description=Silverbullet Daemon
After=syslog.target network.target

[Service]
User=root
Type=simple
ExecStart=/opt/silverbullet/bin/silverbullet --hostname 0.0.0.0 --port 3000 /opt/silverbullet/space
WorkingDirectory=/opt/silverbullet
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q silverbullet
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf silverbullet-server-linux-x86_64.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
