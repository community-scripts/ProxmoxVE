#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Kaedon Cleland-Host (dracentis)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mattermost.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_warn "WARNING: This script will run an external installer from a third-party source (https://mattermost.com/)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://deb.packages.mattermost.com/repo-setup.sh"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

PG_VERSION="16" setup_postgresql

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
} >>~/mattermost.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing Mattermost"
IPADDRESS=$(hostname -I | awk '{print $1}')
curl -fsSL -o /usr/share/keyrings/mattermost-archive-keyring.gpg https://deb.packages.mattermost.com/pubkey.gpg
sh -c 'curl -fsSL https://deb.packages.mattermost.com/repo-setup.sh | sudo bash -s mattermost' >/dev/null
$STD apt update
$STD apt install -y mattermost
$STD install -C -m 600 -o mattermost -g mattermost /opt/mattermost/config/config.defaults.json /opt/mattermost/config/config.json
sed -i -e "/DataSource/c\   \"DataSource\": \"postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME?sslmode=disable&connect_timeout=10\"," \
  -e "/SiteURL/c\   \"SiteURL\": \"http://$IPADDRESS:8065\"," /opt/mattermost/config/config.json
systemctl enable -q --now mattermost
msg_ok "Installed Mattermost"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
