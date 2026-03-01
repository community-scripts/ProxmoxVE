#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/scanopy/scanopy

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
PG_DB_NAME="scanopy_db" PG_DB_USER="scanopy" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db
fetch_and_deploy_gh_release "Scanopy" "scanopy/scanopy" "tarball" "latest" "/opt/scanopy"
TOOLCHAIN="$(grep "channel" /opt/scanopy/backend/rust-toolchain.toml | awk -F\" '{print $2}')"
RUST_TOOLCHAIN=$TOOLCHAIN setup_rust

msg_info "Creating frontend UI"
export PUBLIC_SERVER_HOSTNAME=default
export PUBLIC_SERVER_PORT=""
cd /opt/scanopy/ui
$STD npm ci --no-fund --no-audit
$STD npm run build
msg_ok "Created frontend UI"

msg_info "Building Scanopy Server (patience)"
cd /opt/scanopy/backend
$STD cargo build --release --bin server
mv ./target/release/server /usr/bin/scanopy-server
msg_ok "Built Scanopy Server"

msg_info "Configuring server for first-run"
cat <<EOF >/opt/scanopy/.env
### - SERVER
SCANOPY_DATABASE_URL=postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME
SCANOPY_WEB_EXTERNAL_PATH="/opt/scanopy/ui/build"
SCANOPY_PUBLIC_URL=http://${LOCAL_IP}:60072
SCANOPY_SERVER_PORT=60072
SCANOPY_LOG_LEVEL=info
SCANOPY_INTEGRATED_DAEMON_URL=http://127.0.0.1:60073
## - uncomment to disable signups
# SCANOPY_DISABLE_REGISTRATION=true
## - uncomment when using TLS
# SCANOPY_USE_SECURE_SESSION_COOKIES=true
## - see https://github.com/imbolc/axum-client-ip?tab=readme-ov-file#configurable-vs-specific-extractors
## - before uncommenting the below
# SCANOPY_CLIENT_IP_SOURCE=

### - SMTP (password reset and notifications - optional)
# SCANOPY_SMTP_RELAY=smtp.gmail.com:587
# SCANOPY_SMTP_USERNAME=your-email@gmail.com
# SCANOPY_SMTP_PASSWORD=your-app-password
# SCANOPY_SMTP_EMAIL=scanopy@yourdomain.tld

### - INTEGRATED DAEMON
SCANOPY_SERVER_URL=http://127.0.0.1:60072
SCANOPY_BIND_ADDRESS=0.0.0.0
SCANOPY_NAME="scanopy-daemon"
SCANOPY_HEARTBEAT_INTERVAL=30

### - see https://github.com/scanopy/scanopy/blob/main/docs/CONFIGURATION.md for more options
EOF

cat <<EOF >/etc/systemd/system/scanopy-server.service
[Unit]
Description=Scanopy Network Discovery Server
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/scanopy/backend
EnvironmentFile=/opt/scanopy/.env
ExecStart=/usr/bin/scanopy-server
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now scanopy-server

# Creating short script to configure scanopy-daemon
# cat <<EOF >~/configure_daemon.sh
# #!/usr/bin/env bash
#
# echo "Auto-configuring integrated daemon..."
#
# NETWORK_ID="\$(sudo -u postgres psql -1 -t -d "${PG_DB_NAME}" -c 'SELECT id FROM networks;')"
# API_KEY="\$(sudo -u postgres psql -1 -t -d "${PG_DB_NAME}" -c 'SELECT key FROM api_keys;')"
#
# cat <<END >/etc/systemd/system/scanopy-daemon.service
# [Unit]
# Description=Scanopy Network Discovery Daemon
# After=network-online.target
# Wants=network-online.target
#
# [Service]
# Type=simple
# User=root
# ExecStart=/usr/bin/scanopy-daemon --server-url http://127.0.0.1:60072 --network-id \${NETWORK_ID} --daemon-api-key \${API_KEY} --mode push
# Restart=always
# RestartSec=10
# StandardOutput=journal
# StandardError=journal
#
# [Install]
# WantedBy=multi-user.target
# END
#
# systemctl enable -q --now scanopy-daemon
# echo "Scanopy daemon configured and running"
#
# EOF
# chmod +x ~/configure_daemon.sh
msg_ok "Scanopy server running - please create an account, daemon API key and daemon in the Scanopy UI."

motd_ssh
customize
cleanup_lxc
