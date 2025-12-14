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
PG_DB_NAME="zabbixdb" PG_DB_USER="zabbix" setup_postgresql_db

read -rp "Choose Zabbix version [1] 7.0 LTS  [2] 7.4 (Latest Stable)  [3] Latest available (default: 2): " ZABBIX_CHOICE
ZABBIX_CHOICE=${ZABBIX_CHOICE:-2}
case "$ZABBIX_CHOICE" in
1) ZABBIX_VERSION="7.0" ;;
2) ZABBIX_VERSION="7.4" ;;
3) ZABBIX_VERSION=$(curl -fsSL https://repo.zabbix.com/zabbix/ |
  grep -oP '(?<=href=")[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n1) ;;
*)
  ZABBIX_VERSION="7.4"
  echo "Invalid choice. Defaulting to 7.4."
  ;;
esac

msg_info "Installing Zabbix $ZABBIX_VERSION"
cd /tmp
ZABBIX_DEB_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian13_all.deb"
curl -fsSL "$ZABBIX_DEB_URL" -o /tmp/zabbix-release_latest+debian13_all.deb
$STD dpkg -i /tmp/zabbix-release_latest+debian13_all.deb
$STD apt update
$STD apt install -y zabbix-server-pgsql zabbix-frontend-php php8.4-pgsql zabbix-apache-conf zabbix-sql-scripts
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u "$PG_DB_USER" psql "$PG_DB_NAME" &>/dev/null
sed -i "s/^DBName=.*/DBName=$PG_DB_NAME/" /etc/zabbix/zabbix_server.conf
sed -i "s/^DBUser=.*/DBUser=$PG_DB_USER/" /etc/zabbix/zabbix_server.conf
sed -i "s/^# DBPassword=.*/DBPassword=$PG_DB_PASS/" /etc/zabbix/zabbix_server.conf
msg_ok "Installed Zabbix $ZABBIX_VERSION"

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
rm -rf /tmp/zabbix-release_latest+debian13_all.deb
msg_ok "Started Services"

motd_ssh
customize
cleanup_lxc
