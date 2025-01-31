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
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing HyperHDR"
curl -fsSL https://awawa-dev.github.io/hyperhdr.public.apt.gpg.key >/usr/share/keyrings/hyperhdr.public.apt.gpg.key
chmod go+r /usr/share/keyrings/hyperhdr.public.apt.gpg.key
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hyperhdr.public.apt.gpg.key] https://awawa-dev.github.io $(awk -F= '/VERSION_CODENAME/ {print $2}' /etc/os-release) main" >/etc/apt/sources.list.d/hyperhdr.list
$STD apt-get update
$STD apt-get install -y hyperhdr
msg_ok "Installed HyperHDR"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hyperhdr.service
[Unit]
Description=HyperHDR Service
After=syslog.target network.target

[Service]
Restart=on-failure
RestartSec=5
Type=simple
ExecStart=/usr/bin/hyperhdr

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hyperhdr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
