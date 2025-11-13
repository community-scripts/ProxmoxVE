#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mayanayza/netvisor

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential
msg_ok "Installed Dependencies"

PG_VERSION=17 setup_postgresql
NODE_VERSION="24" setup_nodejs

msg_info "Setting up PostgreSQL Database"
DB_NAME=netvisor_db
DB_USER=netvisor
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME to $DB_USER;"
{
  echo "Netvisor-Credentials"
  echo "Netvisor Database User: $DB_USER"
  echo "Netvisor Database Password: $DB_PASS"
  echo "Netvisor Database Name: $DB_NAME"
} >>~/netvisor.creds
msg_ok "Set up PostgreSQL Database"

fetch_and_deploy_gh_release "netvisor" "mayanayza/netvisor" "tarball" "latest" "/opt/netvisor"

TOOLCHAIN="$(grep "channel" /opt/netvisor/backend/rust-toolchain.toml | awk -F\" '{print $2}')"
RUST_TOOLCHAIN=$TOOLCHAIN setup_rust

msg_info "Creating frontend UI"
export PUBLIC_SERVER_HOSTNAME=default
export PUBLIC_SERVER_PORT=60072
cd /opt/netvisor/ui
$STD npm ci --no-fund --no-audit
$STD npm run build
msg_ok "Created frontend UI"

msg_info "Building Netvisor-server (patience)"
cd /opt/netvisor/backend
$STD cargo build --release --bin server
mv ./target/release/server /usr/bin/netvisor-server
msg_ok "Built Netvisor-server"

msg_info "Building Netvisor-daemon (amd64 version)"
$STD cargo build --release --bin daemon
cp ./target/release/daemon /usr/bin/netvisor-daemon
msg_ok "Built Netvisor-daemon (amd64 version)"

msg_info "Configuring server & daemon for first-run"
cat <<EOF >/opt/netvisor/.env
### - UI
PUBLIC_SERVER_HOSTNAME=default
## - comment out below when using reverse proxy
PUBLIC_SERVER_PORT=60072

### - SERVER
NETVISOR_DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME
NETVISOR_WEB_EXTERNAL_PATH="/opt/netvisor/ui/build"
NETVISOR_SERVER_PORT=60072
NETVISOR_LOG_LEVEL=info
NETVISOR_INTEGRATED_DAEMON_URL=http://127.0.0.1:60073
## - uncomment to disable signups
# NETVISOR_DISABLE_REGISTRATION=true
## - uncomment when behind reverse proxy
# NETVISOR_USE_SECURE_SESSION_COOKIES=true

### - OIDC (optional)
# NETVISOR_OIDC_ISSUER_URL=
# NETVISOR_OIDC_CLIENT_ID=
# NETVISOR_OIDC_CLIENT_SECRET=
# NETVISOR_OIDC_PROVIDER_NAME=
# NETVISOR_OIDC_REDIRECT_URL=
## - Callback URL for reference
# http://your-netvisor-domain:60072/api/auth/oidc/callback

### - INTEGRATED DAEMON
NETVISOR_SERVER_TARGET=127.0.0.1
NETVISOR_BIND_ADDRESS=0.0.0.0
NETVISOR_NAME="netvisor-daemon"
NETVISOR_HEARTBEAT_INTERVAL=30
EOF

cat <<EOF >/etc/systemd/system/netvisor-server.service
[Unit]
Description=NetVisor Network Discovery Server
After=network.target postgresql.service

[Service]
Type=simple
EnvironmentFile=/opt/netvisor/.env
ExecStart=/usr/bin/netvisor-server
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl -q enable --now netvisor-server
sleep 5
NETWORK_ID="$(sudo -u postgres psql -1 -t -d $DB_NAME -c 'SELECT id FROM networks;')"
API_KEY="$(sudo -u postgres psql -1 -t -d $DB_NAME -c 'SELECT key from api_keys;')"

cat <<EOF >/etc/systemd/system/netvisor-daemon.service
[Unit]
Description=NetVisor Network Discovery Daemon
After=network.target netvisor-server.service

[Service]
Type=simple
EnvironmentFile=/opt/netvisor/.env
ExecStart=/usr/bin/netvisor-daemon --server-target http://127.0.0.1 --server-port 60072 --network-id ${NETWORK_ID} --daemon-api-key ${API_KEY}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl -q enable --now netvisor-daemon
msg_ok "Netvisor server & daemon configured and running"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
