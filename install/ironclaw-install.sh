#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nearai/ironclaw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  dbus-user-session \
  gnome-keyring \
  libsecret-tools
msg_ok "Installed Dependencies"

msg_info "Installing PostgreSQL"
PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="ironclaw" PG_DB_USER="ironclaw" PG_DB_EXTENSIONS="vector" setup_postgresql_db
msg_ok "Installed PostgreSQL"

fetch_and_deploy_gh_release "ironclaw-bin" "nearai/ironclaw" "prebuild" "latest" "/usr/local/bin" \
  "ironclaw-$(uname -m)-unknown-linux-gnu.tar.gz"
chmod +x /usr/local/bin/ironclaw

msg_info "Generating gateway authentication token"
GATEWAY_TOKEN=$(openssl rand -hex 32)
mkdir -p /root/.ironclaw
{
    echo "Gateway-Token"
    echo "Token: $GATEWAY_TOKEN"
} >> /root/.ironclaw/gateway.creds
msg_ok "Generated gateway authentication token"

msg_info "Generating Environment file"
cat <<EOF >/root/.ironclaw/.env
DATABASE_BACKEND=postgres
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}?sslmode=disable
GATEWAY_ENABLED=true
GATEWAY_HOST=0.0.0.0
GATEWAY_PORT=3000
GATEWAY_AUTH_TOKEN=${GATEWAY_TOKEN}
CLI_ENABLED=false
RUST_LOG=ironclaw=info,tower_http=info
EOF
msg_ok "Generated Environment file"

msg_info "Configuring IronClaw"
# Set values in the database since it is typically the true source of truth and ensures values are set correctly on first run before the service starts.
/usr/local/bin/ironclaw --no-onboard config set database_backend postgres >/dev/null
/usr/local/bin/ironclaw --no-onboard config set database_url "postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}?sslmode=disable" >/dev/null
/usr/local/bin/ironclaw --no-onboard config set channels.gateway_enabled true >/dev/null
/usr/local/bin/ironclaw --no-onboard config set channels.gateway_host 0.0.0.0 >/dev/null
/usr/local/bin/ironclaw --no-onboard config set channels.gateway_port 3000 >/dev/null
/usr/local/bin/ironclaw --no-onboard config set channels.gateway_auth_token "${GATEWAY_TOKEN}" >/dev/null
/usr/local/bin/ironclaw --no-onboard config set channels.cli_enabled false >/dev/null
/usr/local/bin/ironclaw --no-onboard config set secrets_master_key_source none >/dev/null
# Running ironclaw defaults to use env for secrets and creates this entry, but we want to set that during onboard.
sleep 5
sed -i '/SECRETS_MASTER_KEY/d' /root/.ironclaw/.env
msg_ok "Configured IronClaw"

msg_info "Creating Service"1
cat <<EOF >/etc/systemd/system/ironclaw.service
[Unit]
Description=IronClaw AI Agent
After=network.target postgresql.service

[Service]
Type=simple
Environment=DATABASE_BACKEND=postgres
Environment=DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}?sslmode=disable
Environment=GATEWAY_ENABLED=true
Environment=GATEWAY_HOST=0.0.0.0
Environment=GATEWAY_PORT=3000
Environment=GATEWAY_AUTH_TOKEN=${GATEWAY_TOKEN}
Environment=CLI_ENABLED=false
ExecStart=/usr/local/bin/ironclaw run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q ironclaw
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
