#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://graylog.org/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Setup MongoDB"
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" >/etc/apt/sources.list.d/mongodb-org-7.0.list
$STD apt-get update
$STD apt-get install -y mongodb-org
$STD apt-mark hold mongodb-org
systemctl enable -q --now mongod
msg_ok "Setup MongoDB"

msg_info "Setup Graylog Data Node"
PASSWORD_SECRET=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)
wget -q https://packages.graylog2.org/repo/packages/graylog-6.1-repository_latest.deb
$STD dpkg -i graylog-6.1-repository_latest.deb
$STD apt-get update
$STD apt-get install graylog-datanode -y
sed -i "s/password_secret =/password_secret = $PASSWORD_SECRET/g" /etc/graylog/datanode/datanode.conf
systemctl enable -q --now graylog-datanode
msg_ok "Setup Graylog Data Node"

msg_info "Setup ${APPLICATION}"
$STD apt-get install graylog-server
ROOT_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)
{
    echo "${APPLICATION} Credentials"
    echo "Admin User: admin"
    echo "Admin Password: ${ROOT_PASSWORD}"
} >> ~/graylog.creds
ROOT_PASSWORD=$(echo -n $ROOT_PASSWORD | shasum -a 256 | awk '{print $1}')
sed -i "s/password_secret =/password_secret = $PASSWORD_SECRET/g" /etc/graylog/server/server.conf
sed -i "s/root_password_sha2 =/root_password_sha2 = $ROOT_PASSWORD/g" /etc/graylog/server/server.conf
sed -i 's/#http_bind_address = 127.0.0.1.*/http_bind_address = 0.0.0.0:9000/g' /etc/graylog/server/server.conf
systemctl enable -q --now graylog-server
msg_ok "Setup ${APPLICATION}"

motd_ssh
customize

msg_info "Cleaning up"
rm -f graylog-*-repository_latest.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"