#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/coder/coder

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_postgresql
PG_DB_NAME="coder" PG_DB_USER="coder" PG_DB_CREDS_FILE="/dev/null" setup_postgresql_db

fetch_and_deploy_gh_release "coder" "coder/coder" "binary" "latest" "" "coder_*_linux_$(arch_resolve "amd64" "arm64").deb"

var_access_url="${var_access_url:-http://${LOCAL_IP}:3000}"
if [[ ! "$var_access_url" =~ ^https?:// ]]; then
  msg_warn "Access URL '${var_access_url}' has no scheme, using http://${var_access_url}"
  var_access_url="http://${var_access_url}"
fi

msg_info "Configuring Coder"
cat <<EOF >/etc/coder.d/coder.env
CODER_HTTP_ADDRESS=0.0.0.0:3000
CODER_ACCESS_URL=${var_access_url}
CODER_PG_CONNECTION_URL=postgres://coder:${PG_DB_PASS}@127.0.0.1:5432/coder?sslmode=disable
EOF
chmod 640 /etc/coder.d/coder.env
chown root:coder /etc/coder.d/coder.env
mkdir -p /opt/coder_data
cat <<EOF >/opt/coder_data/.env
CODER_ADMIN_USERNAME=admin
CODER_ADMIN_EMAIL=${var_admin_email:-admin@coder.local}
CODER_ADMIN_PASSWORD=${var_admin_pass:-$(random_password)}
EOF
chmod 600 /opt/coder_data/.env
# The first start runs all database migrations before it reports ready, longer than 90s on slow disks
mkdir -p /etc/systemd/system/coder.service.d
cat <<EOF >/etc/systemd/system/coder.service.d/override.conf
[Service]
TimeoutStartSec=30min
EOF
systemctl daemon-reload
systemctl enable -q --now coder
msg_ok "Configured Coder"

msg_info "Creating Coder Admin"
source /opt/coder_data/.env
for _ in {1..60}; do
  curl -fsS http://127.0.0.1:3000/healthz >/dev/null 2>&1 && break
  sleep 2
done
$STD coder login http://127.0.0.1:3000 \
  --first-user-username "$CODER_ADMIN_USERNAME" \
  --first-user-email "$CODER_ADMIN_EMAIL" \
  --first-user-password "$CODER_ADMIN_PASSWORD" \
  --first-user-full-name "Admin" \
  --first-user-trial=false
msg_ok "Created Coder Admin"

motd_ssh
customize
cleanup_lxc
