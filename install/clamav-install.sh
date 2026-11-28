#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: cisox
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.clamav.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing ClamAV"
echo "clamav-daemon clamav-daemon/TcpOrLocal select TCP" | debconf-set-selections
echo "clamav-daemon clamav-daemon/TCPSocket string 3310" | debconf-set-selections
echo "clamav-daemon clamav-daemon/TCPAddr string 0.0.0.0" | debconf-set-selections
mkdir -p /etc/systemd/system/clamav-daemon.socket.d
cat <<EOF >/etc/systemd/system/clamav-daemon.socket.d/tcp.conf
[Socket]
ListenStream=3310
EOF
$STD apt install -y \
  clamav \
  clamav-daemon \
  clamav-freshclam
msg_ok "Installed ClamAV"

msg_info "Downloading ClamAV Signatures"
systemctl stop clamav-freshclam
$STD freshclam
systemctl enable -q --now clamav-freshclam clamav-daemon
msg_ok "Downloaded ClamAV Signatures"

motd_ssh
customize
cleanup_lxc
