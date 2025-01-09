#!/usr/bin/env bash

# Copyright (c) 2021-2024
# Author: thisisjeron
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
  sudo \
  curl \
  mc \
  imagemagick \
  xvfb \
  libxcomposite1
msg_ok "Installed Dependencies"

msg_info "Installing Calibre"
$STD bash -c "$(curl -fsSL https://download.calibre-ebook.com/linux-installer.sh)"
useradd -c "Calibre Server" -d /opt/calibre -s /bin/bash -m calibre
mkdir -p /opt/calibre/calibre-library
chown -R calibre:calibre /opt/calibre
msg_ok "Installed Calibre"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/calibre-server.service
[Unit]
Description=Calibre Content Server
After=network.target

[Service]
Type=simple
User=calibre
Group=calibre
ExecStart=/opt/calibre/calibre-server --port=8180 --enable-local-write /opt/calibre/calibre-library
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now calibre-server.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
 
