#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.mongodb.com/de-de

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

read -p "${TAB3}Do you want to install MongoDB 8.0 instead of 7.0? [y/N]: " install_mongodb_8
if [[ "$install_mongodb_8" =~ ^[Yy]$ ]]; then
  MONGODB_VERSION="8.0"
else
  MONGODB_VERSION="7.0"
fi

msg_info "Installing MongoDB $MONGODB_VERSION"
curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc" | gpg --dearmor >/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg
cat <<EOF >/etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.sources
Types: deb
URIs: http://repo.mongodb.org/apt/debian
Suites: $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d'=' -f2)/mongodb-org/${MONGODB_VERSION}
Components: main
Signed-By: /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg
EOF
$STD apt update
$STD apt install -y mongodb-org
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
systemctl enable -q --now mongod
msg_ok "Installed MongoDB $MONGODB_VERSION"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
