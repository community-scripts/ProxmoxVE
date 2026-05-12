#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PatcMmon/PatchMon

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="patchmon_db" PG_DB_USER="patchmon_usr" setup_postgresql_db

RELEASE="v2.0.2"
fetch_and_deploy_gh_release "PatchMon" "PatchMon/PatchMon" "singlefile" "latest" "/opt/patchmon" "patchmon-server-linux-amd64"
mv /opt/patchmon/PatchMon /opt/patchmon/patchmon-server

msg_info "Configuring PatchMon"
cat <<EOF >/opt/patchmon/.env
DATABASE_URL="postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME"
JWT_SECRET="$(openssl rand -hex 64)"
SESSION_SECRET="$(openssl rand -hex 64)"
AI_ENCRYPTION_KEY="$(openssl rand -hex 64)"
CORS_ORIGIN=http://${LOCAL_IP}:3000
PORT=3000
APP_ENV=production

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

## OIDC / SSO (when OIDC_ENABLED=true, issuer/client/secret/redirect required)
# OIDC_ENABLED=false
# OIDC_ISSUER_URL=
# OIDC_CLIENT_ID=
# OIDC_CLIENT_SECRET=
# OIDC_REDIRECT_URI=
# OIDC_SCOPES=openid email profile groups
# OIDC_AUTO_CREATE_USERS=false
# OIDC_DEFAULT_ROLE=user
# OIDC_DISABLE_LOCAL_AUTH=false
# OIDC_BUTTON_TEXT=Login with SSO
# OIDC_SESSION_TTL=600
# OIDC_POST_LOGOUT_URI=
# OIDC_SYNC_ROLES=false
# OIDC_ADMIN_GROUP=
# OIDC_SUPERADMIN_GROUP=
# OIDC_HOST_MANAGER_GROUP=
# OIDC_READONLY_GROUP=
# OIDC_USER_GROUP=
# OIDC_ENFORCE_HTTPS=true

AGENT_BINARIES_DIR=/opt/patchmon/agents
EOF
msg_ok "Configured PatchMon"

msg_info "Fetching PatchMon agent binaries"
RELEASE=$(get_latest_github_release "PatchMon/PatchMon")
mkdir -p /opt/patchmon/agents
FILE_URL="https://github.com/PatchMon/PatchMon/releases/download/v${RELEASE}/patchmon-agent-"
AGENT_NAME=(
  "linux-amd64"
  "linux-arm64"
  "linux-arm"
  "linux-386"
  "freebsd-amd64"
  "freebsd-arm64"
  "freebsd-arm"
  "freebsd-386"
  "windows-amd64.exe"
  "windows-arm64.exe"
)
for arch in "${AGENT_NAME[@]}"; do
  curl_with_retry "${FILE_URL}${arch}" "/opt/patchmon/agents/patchmon-agent-${arch}"
  [[ "${arch}" != *.exe ]] && chmod 755 "/opt/patchmon/agents/patchmon-agent-${arch}"
done
msg_ok "Fetched PatchMon agent binaries"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/patchmon-server.service
[Unit]
Description=PatchMon Server
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/patchmon
ExecStart=/opt/patchmon/patchmon-server
Restart=always
RestartSec=10
Environment=PATH=/usr/bin:/usr/local/bin
EnvironmentFile=/opt/patchmon/.env
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/patchmon

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now patchmon-server
msg_ok "Created and started service"

motd_ssh
customize
cleanup_lxc
