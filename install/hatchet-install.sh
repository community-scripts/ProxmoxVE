#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hatchet-dev/hatchet

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

var_admin_email="${var_admin_email:-admin@example.com}"
var_admin_pass="${var_admin_pass:-}"
until [[ ${#var_admin_pass} -ge 8 && ${#var_admin_pass} -le 64 && "$var_admin_pass" =~ [A-Z] && "$var_admin_pass" =~ [a-z] && "$var_admin_pass" =~ [0-9] ]]; do
  var_admin_pass=$(random_password)
done

msg_info "Installing Dependencies"
$STD apt install -y python3
msg_ok "Installed Dependencies"

setup_postgresql
PG_DB_NAME="hatchet" PG_DB_USER="hatchet" setup_postgresql_db
setup_go
fetch_and_deploy_gh_release "hatchet" "hatchet-dev/hatchet" "tarball"
NODE_VERSION="24" NODE_MODULE="$(jq -r '.packageManager' /opt/hatchet/frontend/app/package.json)" setup_nodejs

msg_info "Building Hatchet"
cd /opt/hatchet/frontend/snippets
$STD python3 generate.py
cd /opt/hatchet/frontend/app
$STD pnpm install --frozen-lockfile
$STD pnpm run build
cd /opt/hatchet
for target in lite admin migrate; do
  CGO_ENABLED=0 $STD go build -ldflags="-w -s -X main.Version=v$(cat ~/.hatchet)" -o "bin/hatchet-${target}" "./cmd/hatchet-${target}"
done
rm -rf /opt/hatchet/frontend/app/node_modules ~/.local/share/pnpm/store
$STD go clean -cache -modcache
msg_ok "Built Hatchet"

msg_info "Configuring Hatchet"
mkdir -p /opt/hatchet_data/config
cat <<EOF >/opt/hatchet_data/.env
DATABASE_URL=postgresql://hatchet:${PG_DB_PASS}@localhost:5432/hatchet?sslmode=disable
SERVER_URL=http://${LOCAL_IP}:8888
SERVER_AUTH_COOKIE_DOMAIN=${LOCAL_IP}
SERVER_AUTH_COOKIE_INSECURE=t
SERVER_AUTH_SET_EMAIL_VERIFIED=t
SERVER_ALLOW_SIGNUP=f
SERVER_GRPC_BIND_ADDRESS=0.0.0.0
SERVER_GRPC_PORT=7077
SERVER_GRPC_INSECURE=t
SERVER_GRPC_BROADCAST_ADDRESS=${LOCAL_IP}:7077
SERVER_INTERNAL_CLIENT_INTERNAL_GRPC_BROADCAST_ADDRESS=localhost:7077
SERVER_MSGQUEUE_KIND=postgres
LITE_STATIC_ASSET_DIR=/opt/hatchet/frontend/app/dist
LITE_FRONTEND_BASE_PATH=/
LITE_FRONTEND_PORT=8081
LITE_RUNTIME_PORT=8888
ADMIN_EMAIL=${var_admin_email}
ADMIN_PASSWORD=${var_admin_pass}
EOF
chmod 600 /opt/hatchet_data/.env
cd /opt/hatchet_data
set -a && source /opt/hatchet_data/.env && set +a
$STD /opt/hatchet/bin/hatchet-migrate
$STD /opt/hatchet/bin/hatchet-admin quickstart --config /opt/hatchet_data/config --generated-config-dir /opt/hatchet_data/config --skip certs --overwrite=false
msg_ok "Configured Hatchet"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hatchet.service
[Unit]
Description=Hatchet
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/hatchet_data
EnvironmentFile=/opt/hatchet_data/.env
ExecStartPre=/opt/hatchet/bin/hatchet-migrate
ExecStart=/opt/hatchet/bin/hatchet-lite --config /opt/hatchet_data/config
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hatchet
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
