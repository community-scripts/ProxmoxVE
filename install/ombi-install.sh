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

msg_info "Installing Ombi"
RELEASE=$(curl -sL https://api.github.com/repos/Ombi-app/Ombi/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
wget -q https://github.com/Ombi-app/Ombi/releases/download/${RELEASE}/linux-x64.tar.gz
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
mkdir -p /opt/ombi
tar -xzf linux-x64.tar.gz -C /opt/ombi
rm -rf linux-x64.tar.gz
msg_ok "Installed Ombi"

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
systemctl enable -q --now ombi.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
