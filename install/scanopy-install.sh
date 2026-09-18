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

PG_VERSION=17 setup_postgresql
PG_DB_NAME="scanopy_db" PG_DB_USER="scanopy" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db
fetch_and_deploy_gh_release "Scanopy" "scanopy/scanopy" "singlefile" "latest" "/usr/bin" "scanopy-server-linux-$(arch_resolve)"

msg_info "Configuring Scanopy"
mkdir -p /opt/scanopy
cat <<EOF >/opt/scanopy/.env
### - SERVER
SCANOPY_DATABASE_URL=postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME
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
msg_ok "Configured Scanopy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/scanopy-server.service
[Unit]
Description=Scanopy Network Discovery Server
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/scanopy
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
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
