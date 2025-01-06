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


####ADD user ?


# Installing Dependencies with the 3 core dependencies (curl;sudo;mc)
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


#allow nginx through firewall
$STD ufw allow 'Nginx Full'

# Enter mysql
$STD mysql
# Update permissions
$STD ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'ghost';
# Reread permissions
$STD FLUSH PRIVILEGES;
# exit mysql
$STD exit




msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing npm"
$STD apt-get install -y npm
msg_ok "Installed npm"


$STD npm install ghost-cli@latest -g

msg_info "Setting up Ghost"
mkdir -p /var/www/ghost
chown -R $USER:$USER /var/www/ghost
chmod 775 /var/www/ghost
cd /var/www/ghost


ghost install --db=mysql --dbhost=localhost --dbuser=root --dbpass=ghost --dbname=ghost --no-prompt --no-setup-linux-user --no-setup-nginx --no-setup-ssl --no-setup-systemd
msg_ok "Ghost setup completed"

# Creating Service (if needed)
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/${APPLICATION}.service
[Unit]
Description=${APPLICATION} Service
After=network.target

[Service]
ExecStart=/usr/bin/ghost run
WorkingDirectory=/var/www/ghost
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

motd_ssh
customize