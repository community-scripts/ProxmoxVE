#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: fabrice1236
# License: MIT
# Source: https://ghost.org/

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Install Dependencies
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

# Allow nginx through firewall
$STD ufw allow 'Nginx Full'

# Configure MySQL
msg_info "Configuring MySQL"
$STD mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'ghost';"
$STD mysql -u root -p'ghost' -e "FLUSH PRIVILEGES;"
msg_ok "Configured MySQL"


# Set up Node.js Repository
msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

# Install Node.js (includes npm)
msg_info "Installing Node.js and npm"
$STD apt-get install -y nodejs
$STD apt-get install -y npm
msg_ok "Installed Node.js and npm"

# Install Ghost CLI
msg_info "Installing Ghost CLI"
$STD npm install ghost-cli@latest -g
msg_ok "Installed Ghost CLI"


# Create a new user for Ghost
msg_info "Creating ghost-user"
$STD adduser --disabled-password --gecos "Ghost user" ghost-user
$STD usermod -aG sudo ghost-user
msg_ok "Created ghost-user"

# Set up Ghost
msg_info "Setting up Ghost"
mkdir -p /var/www/ghost
chown -R ghost-user:ghost-user /var/www/ghost
chmod 775 /var/www/ghost
sudo -u ghost-user -H sh -c "cd /var/www/ghost && ghost install --db=mysql --dbhost=localhost --dbuser=root --dbpass=ghost --dbname=ghost --url=http://localhost:2368 --no-prompt --no-setup-linux-user --no-setup-nginx --no-setup-ssl --no-setup-systemd --no-setup-mysql --no-start --no-enable"
msg_ok "Ghost setup completed"

# Creating Service (if needed)
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/${APPLICATION}.service
[Unit]
Description=${APPLICATION} Service
After=network.target

[Service]
Type=simple
Environment="NODE_ENV=production"
ExecStart=/usr/bin/node /usr/bin/ghost run
WorkingDirectory=/var/www/ghost
User=ghost-user
Group=ghost-user
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ${APPLICATION}.service
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"