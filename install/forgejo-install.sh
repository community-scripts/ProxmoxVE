#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
    git \
    git-lfs
msg_ok "Installed Dependencies"

fetch_and_deploy_codeberg_release "forgejo" "forgejo/forgejo" "singlefile" "latest" "/opt/forgejo" "forgejo-*-linux-amd64"
ln -sf /opt/forgejo/forgejo /usr/local/bin/forgejo

msg_info "Setting up Forgejo"
$STD adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git
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
Environment=USER=git HOME=/home/git FORGEJO_WORK_DIR=/var/lib/forgejo
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now forgejo
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
