#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Kaedon Cleland-Host (dracentis)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mattermost.com/

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
  gpg \
  postgresql 
msg_ok "Installed Dependencies"

msg_info "Setting up PostgreSQL"
DB_NAME=mattermost
DB_USER=mmuser
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME to $DB_USER;"
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "GRANT USAGE, CREATE ON SCHEMA PUBLIC TO $DB_USER;"
{
    echo "Mattermost Credentials"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
    echo "Database Name: $DB_NAME"
} >> ~/mattermost.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing Mattermost"
IPADDRESS=$(hostname -I | awk '{print $1}')
curl -sL -o /usr/share/keyrings/mattermost-archive-keyring.gpg https://deb.packages.mattermost.com/pubkey.gpg
sh -c 'curl -sL https://deb.packages.mattermost.com/repo-setup.sh | sudo bash -s mattermost' >/dev/null
$STD apt-get update
$STD apt-get install -y mattermost
$STD install -C -m 600 -o mattermost -g mattermost /opt/mattermost/config/config.defaults.json /opt/mattermost/config/config.json
sed -i -e "/DataSource/c\   \"DataSource\": \"postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME?sslmode=disable&connect_timeout=10\"," \
       -e "/SiteURL/c\   \"SiteURL\": \"http://$IPADDRESS:8065\"," /opt/mattermost/config/config.json
systemctl enable -q --now mattermost.service
msg_ok "Installed Mattermost"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
