#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: madelyn (DysfunctionalProgramming)
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
  mc \
  sudo \
  openjdk-17-jre
msg_ok "Installed Dependencies"

msg_info "Installing Komga"
RELEASE=$(curl -s https://api.github.com/repos/gotson/komga/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q https://github.com/gotson/komga/releases/download/${RELEASE}/komga-${RELEASE}.jar
mkdir -p /opt/komga
mv -f komga-${RELEASE}.jar /opt/komga/komga.jar
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Komga"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/komga.service
[Unit]
Description=Komga
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=/opt/komga/
ExecStart=/usr/bin/java -jar -Xmx2g komga.jar
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q komga
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
