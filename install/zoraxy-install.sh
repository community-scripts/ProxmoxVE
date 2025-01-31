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

msg_info "Installing Zoraxy (Patience)"
RELEASE=$(curl -s https://api.github.com/repos/tobychui/zoraxy/releases/latest  | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/tobychui/zoraxy/releases/download/${RELEASE}/zoraxy_linux_amd64"
mkdir -p /opt/zoraxy
mv zoraxy_linux_amd64 /opt/zoraxy/zoraxy
chmod +x /opt/zoraxy/zoraxy
ln -s /opt/zoraxy/zoraxy /usr/local/bin/zoraxy
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Zoraxy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/zoraxy.service
[Unit]
Description=General purpose request proxy and forwarding tool
After=syslog.target network-online.target

[Service]
ExecStart=/opt/zoraxy/./zoraxy
WorkingDirectory=/opt/zoraxy/
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zoraxy.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
