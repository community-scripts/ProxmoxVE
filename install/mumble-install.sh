#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.mumble.info/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Mumble"
$STD apt install -y mumble-server
cat <<EOF >~/.mumble
$(get_latest_github_release "mumble-voip/mumble")
EOF
msg_ok "Installed Mumble"

msg_info "Configuring Mumble"
mkdir -p /var/lib/mumble-server
cat <<EOF >/etc/mumble/mumble-server.ini
database=/var/lib/mumble-server/mumble-server.sqlite
sqlite_wal=2
port=64738
users=100
bandwidth=558000
allowping=true
obfuscate=true
ice="tcp -h 127.0.0.1 -p 6502"
icesecretwrite=$(tr -d '-' </proc/sys/kernel/random/uuid)
EOF
chown -R mumble-server:mumble-server /var/lib/mumble-server
chown root:mumble-server /etc/mumble/mumble-server.ini
chmod 640 /etc/mumble/mumble-server.ini
msg_ok "Configured Mumble"

msg_info "Setting SuperUser Password"
MUMBLE_PASSWORD=$(tr -d '-' </proc/sys/kernel/random/uuid)
mumble-server -ini /etc/mumble/mumble-server.ini -supw "$MUMBLE_PASSWORD"
chown -R mumble-server:mumble-server /var/lib/mumble-server
msg_ok "Set SuperUser password: ${MUMBLE_PASSWORD}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mumble-server.service
[Unit]
Description=Mumble Server
After=network.target

[Service]
Type=simple
User=mumble-server
Group=mumble-server
ExecStart=/usr/bin/mumble-server -ini /etc/mumble/mumble-server.ini -fg
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mumble-server
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc