#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/QuantumNous/new-api

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "new-api" "QuantumNous/new-api" "singlefile" "latest" "/opt/new-api" "$(arch_resolve "new-api-v" "new-api-arm64-v")*[0-9]"

msg_info "Configuring New API"
ADMIN_USER="${var_admin_user:-admin}"
ADMIN_PASS="${var_admin_pass:-$(random_password)}"
mkdir -p /opt/new-api_data/logs
cat <<EOF >/opt/new-api_data/.env
PORT=3000
SQLITE_PATH=/opt/new-api_data/new-api.db
SESSION_SECRET=$(openssl rand -hex 32)
CRYPTO_SECRET=$(openssl rand -hex 32)
BATCH_UPDATE_ENABLED=true
NEW_API_ADMIN_USER=${ADMIN_USER}
NEW_API_ADMIN_PASSWORD=${ADMIN_PASS}
EOF
chmod 600 /opt/new-api_data/.env
msg_ok "Configured New API"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/new-api.service
[Unit]
Description=New API
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/new-api_data
EnvironmentFile=/opt/new-api_data/.env
ExecStart=/opt/new-api/new-api --log-dir /opt/new-api_data/logs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now new-api
msg_ok "Created Service"

msg_info "Creating New API Admin Account"
for _ in {1..60}; do
  curl -fsS http://127.0.0.1:3000/api/status &>/dev/null && break
  sleep 1
done
jq -nc --arg u "$ADMIN_USER" --arg p "$ADMIN_PASS" \
  '{username: $u, password: $p, confirmPassword: $p, SelfUseModeEnabled: false, DemoSiteEnabled: false}' |
  curl -fsS -X POST http://127.0.0.1:3000/api/setup -H "Content-Type: application/json" --data-binary @- |
  jq -e '.success' >/dev/null
msg_ok "Created New API Admin Account"

motd_ssh
customize
cleanup_lxc
