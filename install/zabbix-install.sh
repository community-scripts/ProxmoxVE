#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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
$STD apt-get install -y \
  curl \
  sudo \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Zabbix"
cd /tmp
wget -q https://repo.zabbix.com/zabbix/7.2/release/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian12_all.deb
$STD dpkg -i /tmp/zabbix-release_latest+debian12_all.deb
$STD apt-get update
$STD apt-get install -y zabbix-server-pgsql zabbix-frontend-php php8.2-pgsql zabbix-apache-conf zabbix-sql-scripts 
$STD apt-get install -y zabbix-agent2 zabbix-agent2-plugin-*
msg_ok "Installed Zabbix"

msg_info "Setting up PostgreSQL"
$STD apt-get install -y postgresql
DB_NAME=zabbixdb
DB_USER=zabbix
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u $DB_USER psql $DB_NAME &>/dev/null
sed -i "s/^DBName=.*/DBName=$DB_NAME/" /etc/zabbix/zabbix_server.conf
sed -i "s/^DBUser=.*/DBUser=$DB_USER/" /etc/zabbix/zabbix_server.conf
sed -i "s/^# DBPassword=.*/DBPassword=$DB_PASS/" /etc/zabbix/zabbix_server.conf
echo "" >~/zabbix.creds
echo "zabbix Database Credentials" >>~/zabbix.creds
echo "" >>~/zabbix.creds
echo -e "zabbix Database User: \e[32m$DB_USER\e[0m" >>~/zabbix.creds
echo -e "zabbix Database Password: \e[32m$DB_PASS\e[0m" >>~/zabbix.creds
echo -e "zabbix Database Name: \e[32m$DB_NAME\e[0m" >>~/zabbix.creds
msg_ok "Set up PostgreSQL"

msg_info "Starting Services"
systemctl restart zabbix-server zabbix-agent2 apache2
systemctl enable -q --now zabbix-server zabbix-agent2 apache2
msg_ok "Started Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/zabbix-release_latest+debian12_all.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
