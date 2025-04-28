#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wiki.debian.org/AptCacherNg

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Apt-Cacher NG"
DEBIAN_FRONTEND=noninteractive $STD apt-get -o Dpkg::Options::="--force-confold" install -y apt-cacher-ng
sed -i 's/# PassThroughPattern: .* # this would allow CONNECT to everything/PassThroughPattern: .*/' /etc/apt-cacher-ng/acng.conf
cat << EOF >/etc/apt/apt.conf.d/00aptproxy.conf
Acquire::http::Proxy "http://localhost:3142";
EOF
systemctl enable -q --now apt-cacher-ng
msg_ok "Installed Apt-Cacher NG"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
