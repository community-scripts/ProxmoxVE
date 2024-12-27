
#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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
$STD apt-get install -y gnupg
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

# Abfrage für die MongoDB-Version
read -p "Do you want to install MongoDB 8.0 instead of 7.0? [y/N]: " install_mongodb_8
if [[ "$install_mongodb_8" =~ ^[Yy]$ ]]; then
  MONGODB_VERSION="8.0"
else
  MONGODB_VERSION="7.0"
fi

msg_info "Installing MongoDB $MONGODB_VERSION"
wget -qO- https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | gpg --dearmor >/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg] http://repo.mongodb.org/apt/debian $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d'=' -f2)/mongodb-org/${MONGODB_VERSION} main" >/etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
$STD apt-get update
$STD apt-get install -y mongodb-org
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
systemctl enable -q --now mongod.service
msg_ok "Installed MongoDB $MONGODB_VERSION"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
