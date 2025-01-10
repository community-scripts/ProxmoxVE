#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: fabrice1236
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghost.org/

# Import Functions und Setup
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
  nginx \
  mysql-server \
  ca-certificates \
  gnupg
msg_ok "Installed Dependencies"


msg_info "Configuring MySQL"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '$DB_PASS';"
$STD mysql -u root -p"$DB_PASS" -e "FLUSH PRIVILEGES;"
{
    echo "MySQL-Credentials"
    echo "Username: root"
    echo "Password: $DB_PASS"
} >> ~/mysql.creds
msg_ok "Configured MySQL"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Setup Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Setup Node.js"

msg_info "Installing Ghost CLI"
$STD npm install ghost-cli@latest -g
msg_ok "Installed Ghost CLI"

msg_info "Creating Service"
$STD adduser --disabled-password --gecos "Ghost user" ghost-user
$STD usermod -aG sudo ghost-user
echo "ghost-user ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ghost-user
mkdir -p /var/www/ghost
chown -R ghost-user:ghost-user /var/www/ghost
chmod 775 /var/www/ghost
sudo -u ghost-user -H sh -c "cd /var/www/ghost && ghost install --db=mysql --dbhost=localhost --dbuser=root --dbpass=$DB_PASS --dbname=ghost --url=http://localhost:2368 --no-prompt --no-setup-nginx --no-setup-ssl --no-setup-mysql --enable --start --ip 0.0.0.0"
rm /etc/sudoers.d/ghost-user
msg_ok "Creating Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
