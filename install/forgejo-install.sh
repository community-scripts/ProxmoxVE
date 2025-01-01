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
$STD apt-get install -y git-lfs
msg_ok "Installed Dependencies"

msg_info "Installing Forgejo"
mkdir -p /opt/forgejo
RELEASE=$(curl -s https://codeberg.org/api/v1/repos/forgejo/forgejo/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/^v//')
wget -qO /opt/forgejo/forgejo-$RELEASE-linux-amd64 "https://codeberg.org/forgejo/forgejo/releases/download/v${RELEASE}/forgejo-${RELEASE}-linux-amd64"
chmod +x /opt/forgejo/forgejo-$RELEASE-linux-amd64
ln -sf /opt/forgejo/forgejo-$RELEASE-linux-amd64 /usr/local/bin/forgejo
msg_ok "Installed Forgejo"

msg_info "Setting up Forgejo"
$STD adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git  git
mkdir /var/lib/forgejo
chown git:git /var/lib/forgejo
chmod 750 /var/lib/forgejo
mkdir /etc/forgejo
chown root:git /etc/forgejo
chmod 770 /etc/forgejo
msg_ok "Setup Forgejo"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/forgejo.service
[Unit]
Description=Forgejo
After=syslog.target
After=network.target
[Service]
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/forgejo/ 
ExecStart=/usr/local/bin/forgejo web --config /etc/forgejo/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/forgejo
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now forgejo
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
