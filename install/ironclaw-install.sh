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

PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="ironclaw" PG_DB_USER="ironclaw" PG_DB_EXTENSIONS="vector" setup_postgresql_db

fetch_and_deploy_gh_release "ironclaw-bin" "nearai/ironclaw" "prebuild" "latest" "/usr/local/bin" \
  "ironclaw-$(uname -m)-unknown-linux-$([[ -f /etc/alpine-release ]] && echo "musl" || echo "gnu").tar.gz"
chmod +x /usr/local/bin/ironclaw

msg_info "Configuring IronClaw"
mkdir -p /root/.ironclaw
GATEWAY_TOKEN=$(openssl rand -hex 32)
cat <<EOF >/root/.ironclaw/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}?sslmode=disable
GATEWAY_ENABLED=true
GATEWAY_HOST=0.0.0.0
GATEWAY_PORT=3000
GATEWAY_AUTH_TOKEN=${GATEWAY_TOKEN}
CLI_ENABLED=false
AGENT_NAME=ironclaw
RUST_LOG=ironclaw=info,tower_http=info
EOF
chmod 600 /root/.ironclaw/.env
msg_ok "Configured IronClaw"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ironclaw.service
[Unit]
Description=IronClaw AI Agent
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/ironclaw
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
