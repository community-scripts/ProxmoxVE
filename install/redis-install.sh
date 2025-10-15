#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://redis.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  apt-transport-https \
  lsb-release
msg_ok "Installed Dependencies"

msg_info "Installing Redis"
curl -fsSL "https://packages.redis.io/gpg" | gpg --dearmor >/usr/share/keyrings/redis-archive-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/redis.sources
Types: deb
URIs: https://packages.redis.io/deb
Suites: $(lsb_release -cs)
Components: main
Signed-By: /usr/share/keyrings/redis-archive-keyring.gpg
EOF
$STD apt update
$STD apt install -y redis
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
systemctl enable -q --now redis-server
msg_ok "Installed Redis"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
