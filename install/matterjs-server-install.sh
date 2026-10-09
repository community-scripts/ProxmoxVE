#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matter-js/matterjs-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" setup_nodejs

msg_info "Installing MatterJS-Server"
mkdir -p /opt/matter-server
cd /opt/matter-server
$STD npm install matter-server
mkdir -p /var/lib/matterjs-server
msg_ok "Installed MatterJS-Server"

msg_info "Configuring Network"
cat <<EOF >/etc/sysctl.d/60-ipv6-ra-rio.conf
net.ipv6.conf.default.accept_ra=1
net.ipv6.conf.default.accept_ra_rtr_pref=1
net.ipv6.conf.default.accept_ra_rt_info_max_plen=64
net.ipv6.conf.eth0.accept_ra=1
net.ipv6.conf.eth0.accept_ra_rtr_pref=1
net.ipv6.conf.eth0.accept_ra_rt_info_max_plen=64
EOF
$STD sysctl -p /etc/sysctl.d/60-ipv6-ra-rio.conf
msg_ok "Configured Network"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/matterjs-server.service
[Unit]
Description=MatterJS Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/node /opt/matter-server/node_modules/matter-server/dist/esm/MatterServer.js --storage-path /var/lib/matterjs-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now matterjs-server
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
