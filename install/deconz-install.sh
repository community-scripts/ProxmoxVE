#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.phoscon.de/en/conbee2/software#deconz

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting Phoscon Repository"
setup_deb822_repo \
  "deconz" \
  "http://phoscon.de/apt/deconz.pub.key" \
  "http://phoscon.de/apt/deconz" \
  "generic"
msg_ok "Setup Phoscon Repository"

msg_info "Installing deConz"
libssl=$(curl -fsSL "http://security.ubuntu.com/ubuntu/pool/main/o/openssl/" | grep -o 'libssl1\.1_1\.1\.1f-1ubuntu2\.2[^"]*amd64\.deb' | head -n1)
curl -fsSL "http://security.ubuntu.com/ubuntu/pool/main/o/openssl/$libssl" -o "$libssl"
$STD dpkg -i "$libssl"
$STD apt install -y deconz
rm -rf "$libssl"
msg_ok "Installed deConz"

msg_info "Creating Service"
cat <<EOF >/lib/systemd/system/deconz.service
[Unit]
Description=deCONZ: ZigBee gateway -- REST API
Wants=deconz-init.service deconz-update.service
StartLimitIntervalSec=0

[Service]
User=root
ExecStart=/usr/bin/deCONZ -platform minimal --http-port=80
Restart=on-failure
RestartSec=30
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_KILL CAP_SYS_BOOT CAP_SYS_TIME

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now deconz
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
