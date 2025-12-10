#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/netvisor-io/netvisor

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  libssl-dev \
  pkg-config
msg_ok "Installed Dependencies"

PG_VERSION=17 setup_postgresql
NODE_VERSION="24" setup_nodejs
PG_DB_NAME="netvisor_db" PG_DB_USER="netvisor" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db

fetch_and_deploy_gh_release "netvisor" "netvisor-io/netvisor" "tarball" "latest" "/opt/netvisor"

TOOLCHAIN="$(grep "channel" /opt/netvisor/backend/rust-toolchain.toml | awk -F\" '{print $2}')"
RUST_TOOLCHAIN=$TOOLCHAIN setup_rust

msg_info "Creating frontend UI"
export PUBLIC_SERVER_HOSTNAME=default
export PUBLIC_SERVER_PORT=""
cd /opt/netvisor/ui
$STD npm ci --no-fund --no-audit
$STD npm run build
msg_ok "Created frontend UI"

msg_info "Building Netvisor-server (patience)"
cd /opt/netvisor/backend
$STD cargo build --release --bin server
mv ./target/release/server /usr/bin/netvisor-server
msg_ok "Built Netvisor-server"

msg_info "Building Netvisor-daemon"
$STD cargo build --release --bin daemon
cp ./target/release/daemon /usr/bin/netvisor-daemon
msg_ok "Built Netvisor-daemon"

msg_info "Configuring server for first-run"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
cat <<EOF >/opt/netvisor/.env
### - SERVER
NETVISOR_DATABASE_URL=postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME
NETVISOR_WEB_EXTERNAL_PATH="/opt/netvisor/ui/build"
NETVISOR_PUBLIC_URL=http://${LOCAL_IP}:60072
NETVISOR_SERVER_PORT=60072
NETVISOR_LOG_LEVEL=info
NETVISOR_INTEGRATED_DAEMON_URL=http://127.0.0.1:60073
## - uncomment to disable signups
# NETVISOR_DISABLE_REGISTRATION=true
## - uncomment when using TLS
# NETVISOR_USE_SECURE_SESSION_COOKIES=true
## - see https://github.com/imbolc/axum-client-ip?tab=readme-ov-file#configurable-vs-specific-extractors
## - before uncommenting the below
# NETVISOR_CLIENT_IP_SOURCE=

### - SMTP (password reset and notifications - optional)
# NETVISOR_SMTP_RELAY=smtp.gmail.com:587
# NETVISOR_SMTP_USERNAME=your-email@gmail.com
# NETVISOR_SMTP_PASSWORD=your-app-password
# NETVISOR_SMTP_EMAIL=netvisor@yourdomain.tld

### - INTEGRATED DAEMON
NETVISOR_SERVER_URL=http://127.0.0.1:60072
NETVISOR_BIND_ADDRESS=0.0.0.0
NETVISOR_NAME="netvisor-daemon"
NETVISOR_HEARTBEAT_INTERVAL=30

### - see https://github.com/netvisor-io/netvisor/blob/main/docs/CONFIGURATION.md for more options
EOF

cat <<EOF >/etc/systemd/system/netvisor-server.service
[Unit]
Description=NetVisor Network Discovery Server
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/netvisor/backend
EnvironmentFile=/opt/netvisor/.env
ExecStart=/usr/bin/netvisor-server
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now netvisor-server

# Creating short script to configure netvisor-daemon
cat <<EOF >~/configure_daemon.sh
#!/usr/bin/env bash

echo "Auto-configuring integrated daemon..."

NETWORK_ID="\$(sudo -u postgres psql -1 -t -d "${PG_DB_NAME}" -c 'SELECT id FROM networks;')"
API_KEY="\$(sudo -u postgres psql -1 -t -d "${PG_DB_NAME}" -c 'SELECT key FROM api_keys;')"

cat <<END >/etc/systemd/system/netvisor-daemon.service
[Unit]
Description=NetVisor Network Discovery Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/netvisor-daemon --server-url http://127.0.0.1:60072 --network-id \${NETWORK_ID} --daemon-api-key \${API_KEY} --mode push
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
END

systemctl enable -q --now netvisor-daemon
echo "NetVisor daemon configured and running"

EOF
chmod +x ~/configure_daemon.sh
msg_ok "Netvisor server running - please create an account in the UI to continue."

motd_ssh
customize
cleanup_lxc
