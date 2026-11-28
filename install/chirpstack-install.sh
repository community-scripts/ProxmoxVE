#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tom Frenzel (tomfrenzel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/chirpstack/chirpstack

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

if [[ -z "${var_region:-}" ]]; then
  echo -e "${INFO}${YW}Available regions: https://github.com/chirpstack/chirpstack/tree/master/chirpstack/configuration${CL}"
  read -r -p "${TAB3}Gateway region ID (e.g. eu868, us915_0): " var_region || true
fi
if [[ -z "${var_region:-}" ]]; then
  msg_error "Gateway region ID is required (set var_region or enter it when prompted)"
  exit 1
fi

msg_info "Installing Dependencies"
$STD apt install -y \
  mosquitto \
  redis-server
msg_ok "Installed Dependencies"

PG_VERSION="18" setup_postgresql
PG_DB_NAME="chirpstack" PG_DB_USER="chirpstack" PG_DB_EXTENSIONS="pg_trgm" setup_postgresql_db

msg_info "Installing ChirpStack"
setup_deb822_repo \
  "chirpstack" \
  "https://artifacts.chirpstack.io/packages/chirpstack.key" \
  "https://artifacts.chirpstack.io/packages/4.x/deb" \
  "stable" \
  "main"
$STD apt install -y \
  chirpstack-gateway-bridge \
  chirpstack
msg_ok "Installed ChirpStack"

msg_info "Configuring ChirpStack"
sed -i "s|^\(\s*dsn = \).*|\1\"postgres://chirpstack:${PG_DB_PASS}@localhost/chirpstack?sslmode=disable\"|" /etc/chirpstack/chirpstack.toml
if ! grep -Eq "^[[:space:]]*\"${var_region,,}\"[[:space:]]*,?[[:space:]]*$" /etc/chirpstack/chirpstack.toml; then
  sed -i "/^[[:space:]]*enabled_regions = \\[$/a\\    \"${var_region,,}\"," /etc/chirpstack/chirpstack.toml
fi
sed -i -E "s#^(\s*(event|command)_topic_template\s*=\s*\")#\1${var_region,,}/#" /etc/chirpstack-gateway-bridge/chirpstack-gateway-bridge.toml
mkdir -p /etc/systemd/system/chirpstack.service.d
cat <<EOF >/etc/systemd/system/chirpstack.service.d/override.conf
[Unit]
After=postgresql.service redis-server.service mosquitto.service
EOF
systemctl daemon-reload
# the packaged unit starts on the stock DSN, crash-loops and hits its start limit
systemctl reset-failed chirpstack
systemctl restart chirpstack chirpstack-gateway-bridge
msg_ok "Configured ChirpStack"

motd_ssh
customize
cleanup_lxc
