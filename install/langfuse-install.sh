#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stephen Chin (steveonjava)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/langfuse/langfuse

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

if [[ -z "${var_admin_email:-}" ]]; then
  var_admin_email=$(prompt_input "Langfuse admin email:" "admin@example.com" 60)
fi
var_admin_email="${var_admin_email:-admin@example.com}"
if [[ ! "$var_admin_email" =~ ^[A-Za-z0-9_+-]+(\.[A-Za-z0-9_+-]+)*@([A-Za-z0-9][A-Za-z0-9-]*\.)+[A-Za-z]{2,}$ ]]; then
  msg_warn "Invalid email '${var_admin_email}', falling back to admin@example.com"
  var_admin_email="admin@example.com"
fi
var_admin_pass="${var_admin_pass:-}"
if [[ -n "$var_admin_pass" ]] && [[ ${#var_admin_pass} -lt 8 || "$var_admin_pass" == *[[:space:][:cntrl:]\"\'\\]* ]]; then
  msg_warn "Admin password needs at least 8 characters and no spaces, quotes or backslashes, generating one"
  var_admin_pass=""
fi
if [[ -z "$var_admin_pass" ]]; then
  var_admin_pass=$(random_password 24)
fi

msg_info "Installing Dependencies"
$STD apt install -y build-essential redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="langfuse" PG_DB_USER="langfuse" setup_postgresql_db
setup_clickhouse
fetch_and_deploy_gh_release "langfuse" "langfuse/langfuse" "tarball"
NODE_VERSION="24" NODE_MODULE="pnpm@$(jq -r '.engines.pnpm' /opt/langfuse/package.json)" setup_nodejs
RUST_TOOLCHAIN="$(sed -n 's/^channel = "\(.*\)"/\1/p' /opt/langfuse/packages/native/rust-toolchain.toml)" RUST_PROFILE="minimal" setup_rust
fetch_and_deploy_gh_release "migrate" "golang-migrate/migrate" "binary"
fetch_and_deploy_gh_release "seaweedfs" "seaweedfs/seaweedfs" "prebuild" "latest" "/opt/seaweedfs" "linux_$(arch_resolve).tar.gz"

msg_info "Building Langfuse"
cd /opt/langfuse
HUSKY=0 $STD pnpm install --frozen-lockfile
DOCKER_BUILD=1 NEXT_TELEMETRY_DISABLED=1 CI=true pnpm_config_verify_deps_before_run=false $STD pnpm turbo run build --filter=web... --filter=worker... --concurrency=1
cp -r web/.next/static web/.next/standalone/web/.next/
cp -r web/public web/.next/standalone/web/
msg_ok "Built Langfuse"

msg_info "Configuring Langfuse"
mkdir -p /opt/langfuse_data/storage
chmod 700 /opt/langfuse_data
REDIS_PASS=$(random_password 32)
CLICKHOUSE_PASS=$(random_password 32)
S3_SECRET=$(random_password 48)
PUBLIC_KEY="pk-lf-$(random_password 32)"
SECRET_KEY="sk-lf-$(random_password 32)"
cat <<EOF >/opt/langfuse_data/.env
NODE_ENV=production
NEXTAUTH_URL=http://${LOCAL_IP}:3000
NEXTAUTH_SECRET=$(random_password 48)
SALT=$(random_password 48)
ENCRYPTION_KEY=$(openssl rand -hex 32)
DATABASE_URL=postgresql://langfuse:${PG_DB_PASS}@127.0.0.1:5432/langfuse
DIRECT_URL=postgresql://langfuse:${PG_DB_PASS}@127.0.0.1:5432/langfuse
CLICKHOUSE_URL=http://127.0.0.1:8123
CLICKHOUSE_MIGRATION_URL=clickhouse://127.0.0.1:9000
CLICKHOUSE_USER=langfuse
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASS}
CLICKHOUSE_DB=default
CLICKHOUSE_CLUSTER_ENABLED=false
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_AUTH=${REDIS_PASS}
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_EVENT_UPLOAD_PREFIX=events/
LANGFUSE_S3_EVENT_UPLOAD_REGION=us-east-1
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://127.0.0.1:8333
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=langfuse
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=${S3_SECRET}
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true
AUTH_DISABLE_SIGNUP=true
TELEMETRY_ENABLED=false
NEXT_TELEMETRY_DISABLED=1
LANGFUSE_INIT_ORG_ID=default-org
LANGFUSE_INIT_ORG_NAME=Default
LANGFUSE_INIT_PROJECT_ID=default-project
LANGFUSE_INIT_PROJECT_NAME=Default
LANGFUSE_INIT_PROJECT_PUBLIC_KEY=${PUBLIC_KEY}
LANGFUSE_INIT_PROJECT_SECRET_KEY=${SECRET_KEY}
LANGFUSE_INIT_USER_EMAIL=${var_admin_email}
LANGFUSE_INIT_USER_NAME=Admin
LANGFUSE_INIT_USER_PASSWORD=${var_admin_pass}
EOF
chmod 600 /opt/langfuse_data/.env
cat <<EOF >/etc/redis/langfuse.conf
bind 127.0.0.1 ::1
protected-mode yes
requirepass ${REDIS_PASS}
maxmemory-policy noeviction
appendonly yes
EOF
chown root:redis /etc/redis/langfuse.conf
chmod 640 /etc/redis/langfuse.conf
cat <<EOF >>/etc/redis/redis.conf
include /etc/redis/langfuse.conf
EOF
cat <<EOF >/etc/clickhouse-server/users.d/langfuse.xml
<clickhouse>
  <users>
    <default remove="remove"/>
    <langfuse>
      <password_sha256_hex>$(printf '%s' "${CLICKHOUSE_PASS}" | sha256sum | cut -d ' ' -f1)</password_sha256_hex>
      <networks><ip>127.0.0.1</ip><ip>::1</ip></networks>
      <profile>default</profile>
      <quota>default</quota>
      <access_management>1</access_management>
    </langfuse>
  </users>
</clickhouse>
EOF
chown clickhouse:clickhouse /etc/clickhouse-server/users.d/langfuse.xml
chmod 600 /etc/clickhouse-server/users.d/langfuse.xml
cat <<EOF >/etc/clickhouse-server/config.d/langfuse.xml
<clickhouse>
  <listen_host replace="replace">127.0.0.1</listen_host>
  <timezone>UTC</timezone>
</clickhouse>
EOF
cat <<EOF >/opt/langfuse_data/s3.json
{
  "identities": [
    {
      "name": "langfuse",
      "credentials": [{"accessKey": "langfuse", "secretKey": "${S3_SECRET}"}],
      "actions": ["Admin", "Read", "Write", "List", "Tagging"]
    }
  ]
}
EOF
chmod 600 /opt/langfuse_data/s3.json
msg_ok "Configured Langfuse"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/langfuse-storage.service
[Unit]
Description=Langfuse S3 Storage (SeaweedFS)
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/langfuse_data/storage
ExecStart=/opt/seaweedfs/weed server -dir=/opt/langfuse_data/storage -ip=127.0.0.1 -ip.bind=127.0.0.1 -s3 -s3.port=8333 -s3.port.iceberg=0 -s3.port.lance=0 -s3.config=/opt/langfuse_data/s3.json -master.telemetry=false
Restart=on-failure
RestartSec=5
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/langfuse-migrate.service
[Unit]
Description=Langfuse Database Migrations
After=network.target postgresql.service clickhouse-server.service redis-server.service langfuse-storage.service
Wants=postgresql.service clickhouse-server.service redis-server.service langfuse-storage.service
Before=langfuse-web.service langfuse-worker.service

[Service]
Type=oneshot
WorkingDirectory=/opt/langfuse
EnvironmentFile=/opt/langfuse_data/.env
ExecStart=/usr/bin/pnpm --filter @langfuse/shared exec prisma db execute --schema=./prisma/schema.prisma --file=./scripts/cleanup.sql
ExecStart=/usr/bin/pnpm --filter @langfuse/shared exec prisma migrate deploy --schema=./prisma/schema.prisma
ExecStart=/bin/sh /opt/langfuse/packages/shared/clickhouse/scripts/up.sh
RemainAfterExit=yes
TimeoutStartSec=1800
UMask=0077
EOF
cat <<EOF >/etc/systemd/system/langfuse-web.service
[Unit]
Description=Langfuse Web
After=network.target langfuse-migrate.service
Requires=langfuse-migrate.service

[Service]
Type=simple
WorkingDirectory=/opt/langfuse
EnvironmentFile=/opt/langfuse_data/.env
Environment=HOSTNAME=0.0.0.0
Environment=PORT=3000
ExecStart=/usr/bin/node /opt/langfuse/web/.next/standalone/web/server.js
SuccessExitStatus=143
Restart=on-failure
RestartSec=5
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/langfuse-worker.service
[Unit]
Description=Langfuse Worker
After=network.target langfuse-migrate.service
Requires=langfuse-migrate.service

[Service]
Type=simple
WorkingDirectory=/opt/langfuse
EnvironmentFile=/opt/langfuse_data/.env
Environment=HOSTNAME=127.0.0.1
Environment=PORT=3030
ExecStart=/usr/bin/node /opt/langfuse/worker/dist/index.js
Restart=on-failure
RestartSec=5
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
systemctl restart redis-server clickhouse-server
systemctl enable -q --now langfuse-storage
$STD curl --retry 30 --retry-delay 2 --retry-connrefused -fsS http://127.0.0.1:9333/cluster/status
$STD /opt/seaweedfs/weed shell -master=127.0.0.1:9333 <<<"s3.bucket.create -name langfuse"
$STD curl --config - --retry 30 --retry-delay 2 --retry-connrefused -fsS http://127.0.0.1:8333/langfuse <<EOF
aws-sigv4 = "aws:amz:us-east-1:s3"
user = "langfuse:${S3_SECRET}"
EOF
systemctl enable -q --now langfuse-web langfuse-worker
$STD curl --retry 60 --retry-delay 2 --retry-connrefused -fsS http://127.0.0.1:3000/api/public/ready
$STD curl --retry 30 --retry-delay 2 --retry-connrefused -fsS http://127.0.0.1:3030/api/health
msg_ok "Created Services"

msg_info "Saving Credentials"
sed -i '/^LANGFUSE_INIT_/d' /opt/langfuse_data/.env
cat <<EOF >>~/langfuse.creds

Langfuse Admin
Email: ${var_admin_email}
Password: ${var_admin_pass}

Langfuse API Keys (project Default)
Public Key: ${PUBLIC_KEY}
Secret Key: ${SECRET_KEY}
EOF
chmod 600 ~/langfuse.creds
msg_ok "Saved Credentials"

motd_ssh
customize
cleanup_lxc
