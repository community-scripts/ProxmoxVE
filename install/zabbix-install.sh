#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zabbix.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql

msg_info "Installing Zabbix"
cd /tmp
curl -fsSL "$(curl -fsSL https://repo.zabbix.com/zabbix/ |
  grep -oP '(?<=href=")[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n1 |
  xargs -I{} echo "https://repo.zabbix.com/zabbix/{}/release/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian13_all.deb")" \
  -o /tmp/zabbix-release_latest+debian13_all.deb
$STD dpkg -i /tmp/zabbix-release_latest+debian13_all.deb
$STD apt update
$STD apt install -y zabbix-server-pgsql zabbix-frontend-php php8.4-pgsql zabbix-apache-conf zabbix-sql-scripts
msg_ok "Installed Zabbix"

while true; do
  read -rp "Which agent do you want to install? [1=agent (classic), 2=agent2 (modern), default=1]: " AGENT_CHOICE
  case "$AGENT_CHOICE" in
  2)
    AGENT_PKG="zabbix-agent2"
    break
    ;;
  "" | 1)
    AGENT_PKG="zabbix-agent"
    break
    ;;
  *)
    echo "Invalid choice. Please enter 1 or 2."
    ;;
  esac
done
msg_ok "Selected $AGENT_PKG"

if [ "$AGENT_PKG" = "zabbix-agent2" ]; then
  echo "Choose plugins for Zabbix Agent2:"
  echo "1) PostgreSQL only (default, recommended)"
  echo "2) All plugins (may cause issues)"
  read -rp "Choose option [1-2]: " PLUGIN_CHOICE

  case "$PLUGIN_CHOICE" in
  2)
    $STD apt install -y zabbix-agent2 zabbix-agent2-plugin-*
    ;;
  *)
    $STD apt install -y zabbix-agent2 zabbix-agent2-plugin-postgresql
    ;;
  esac

  if [ -f /etc/zabbix/zabbix_agent2.d/plugins.d/nvidia.conf ]; then
    sed -i 's|^Plugins.NVIDIA.System.Path=.*|# Plugins.NVIDIA.System.Path=/usr/libexec/zabbix/zabbix-agent2-plugin-nvidia-gpu|' \
      /etc/zabbix/zabbix_agent2.d/plugins.d/nvidia.conf
  fi
else
  $STD apt install -y zabbix-agent
fi

msg_info "Setting up PostgreSQL"
DB_NAME=zabbixdb
DB_USER=zabbix
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
  echo "Zabbix-Credentials"
  echo "Zabbix Database User: $DB_USER"
  echo "Zabbix Database Password: $DB_PASS"
  echo "Zabbix Database Name: $DB_NAME"
} >>~/zabbix.creds

zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u $DB_USER psql $DB_NAME &>/dev/null
sed -i "s/^DBName=.*/DBName=$DB_NAME/" /etc/zabbix/zabbix_server.conf
sed -i "s/^DBUser=.*/DBUser=$DB_USER/" /etc/zabbix/zabbix_server.conf
sed -i "s/^# DBPassword=.*/DBPassword=$DB_PASS/" /etc/zabbix/zabbix_server.conf
msg_ok "Set up PostgreSQL"

msg_info "Configuring Fping"
if command -v fping >/dev/null 2>&1; then
  FPING_PATH=$(command -v fping)
  sed -i "s|^#\?FpingLocation=.*|FpingLocation=$FPING_PATH|" /etc/zabbix/zabbix_server.conf
fi

if command -v fping6 >/dev/null 2>&1; then
  FPING6_PATH=$(command -v fping6)
  sed -i "s|^#\?Fping6Location=.*|Fping6Location=$FPING6_PATH|" /etc/zabbix/zabbix_server.conf
fi
msg_ok "Configured Fping"

msg_info "Starting Services"
if [ "$AGENT_PKG" = "zabbix-agent2" ]; then
  AGENT_SERVICE="zabbix-agent2"
else
  AGENT_SERVICE="zabbix-agent"
fi

systemctl restart zabbix-server apache2
systemctl enable -q --now zabbix-server $AGENT_SERVICE apache2
msg_ok "Started Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/zabbix-release_latest+debian13_all.deb
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
