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
$STD apk add openssl dbus gnome-keyring
msg_ok "Installed Dependencies"

msg_info "Installing PostgreSQL"
$STD apk add postgresql17 postgresql17-openrc postgresql-pgvector postgresql-common
$STD rc-service postgresql setup
$STD rc-update add postgresql default
$STD rc-service postgresql start
msg_ok "Installed PostgreSQL"

msg_info "Setting up Database"
PG_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD su -s /bin/sh postgres -c "psql -c \"CREATE ROLE ironclaw WITH LOGIN PASSWORD '${PG_PASS}';\""
$STD su -s /bin/sh postgres -c "psql -c \"CREATE DATABASE ironclaw WITH OWNER ironclaw;\""
$STD su -s /bin/sh postgres -c "psql -d ironclaw -c \"CREATE EXTENSION IF NOT EXISTS vector;\""
msg_ok "Set up Database"

fetch_and_deploy_gh_release "ironclaw-bin" "nearai/ironclaw" "prebuild" "latest" "/usr/local/bin" \
  "ironclaw-$(uname -m)-unknown-linux-musl.tar.gz"
chmod +x /usr/local/bin/ironclaw

msg_info "Configuring IronClaw"
mkdir -p /root/.ironclaw
GATEWAY_TOKEN=$(openssl rand -hex 32)
cat <<EOF >/root/.ironclaw/.env
DATABASE_URL=postgresql://ironclaw:${PG_PASS}@localhost:5432/ironclaw?sslmode=disable
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
cat <<EOF >/etc/init.d/ironclaw
#!/sbin/openrc-run

name="IronClaw"
description="IronClaw AI Agent"
command="/usr/bin/dbus-run-session"
command_args="/usr/local/bin/ironclaw"
command_background=true
pidfile="/run/ironclaw.pid"
directory="/root"
supervise_daemon_args="--env-file /root/.ironclaw/.env"

depend() {
  need net postgresql
}
EOF
chmod +x /etc/init.d/ironclaw
$STD rc-update add ironclaw default
msg_ok "Created Service"

motd_ssh
customize
