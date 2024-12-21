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
$STD apt-get install -y imagemagick xvfb libxcomposite1
msg_ok "Installed Dependencies"

msg_info "Installing Calibre (latest)"
# If your container runs as root, you generally do not need to prefix with `sudo`.
# The official Calibre instructions:
wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin
msg_ok "Installed Calibre"

msg_info "Creating calibre system user & directories"
useradd -c "Calibre Server" -d /opt/calibre -s /bin/bash -m calibre
mkdir -p /opt/calibre/calibre-library
chown -R calibre:calibre /opt/calibre
msg_ok "Created calibre user & directories"

msg_info "Creating systemd service"
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
 