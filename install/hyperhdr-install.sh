#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.hyperhdr.eu/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing HyperHDR"
setup_deb822_repo \
  "hyperhdr" \
  "https://awawa-dev.github.io/hyperhdr.public.apt.gpg.key" \
  "https://awawa-dev.github.io" \
  "$(get_os_info codename)"
$STD apt install -y hyperhdr
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
cleanup_lxc
