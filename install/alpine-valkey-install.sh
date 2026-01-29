#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pshankinclarke (lazarillo)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://valkey.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Valkey"
$STD apk add valkey valkey-openrc valkey-cli
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/valkey/valkey.conf

PASS="$(head -c 100 /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c32)"
echo "requirepass $PASS" >>/etc/valkey/valkey.conf
echo "$PASS" >~/valkey.creds
chmod 600 ~/valkey.creds

MEMTOTAL_MB=$(free -m | grep ^Mem: | awk '{print $2}')
MAXMEMORY_MB=$((MEMTOTAL_MB * 75 / 100))

{
  echo ""
  echo "# Memory-optimized settings for small-scale deployments"
  echo "maxmemory ${MAXMEMORY_MB}mb"
  echo "maxmemory-policy allkeys-lru"
  echo "maxmemory-samples 10"
} >>/etc/valkey/valkey.conf
msg_ok "Installed Valkey"

# Note: Alpine's valkey package is compiled without TLS support
# For TLS, use the Debian-based valkey script instead

$STD rc-update add valkey default
$STD rc-service valkey start

motd_ssh
customize
cleanup_lxc
