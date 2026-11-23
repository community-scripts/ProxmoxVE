#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/usesend/useSend

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

PG_VERSION="16" setup_postgresql
PG_DB_NAME="usesend" PG_DB_USER="usesend" setup_postgresql_db

fetch_and_deploy_gh_release "usesend" "usesend/useSend" "tarball"
NODE_VERSION="22" NODE_MODULE="pnpm@$(jq -r '.packageManager | split("@")[1]' /opt/usesend/package.json)" setup_nodejs

msg_info "Building useSend"
cd /opt/usesend
# Puppeteer only comes with the docs tooling (Mintlify) in the root devDependencies; useSend never runs a browser
PUPPETEER_SKIP_DOWNLOAD=true $STD pnpm install --frozen-lockfile --filter "web..." --filter smtp-server
$STD pnpm --filter web db:generate
SKIP_ENV_VALIDATION=true DOCKER_OUTPUT=1 NEXT_TELEMETRY_DISABLED=1 NEXT_PUBLIC_APP_VERSION="v$(cat ~/.usesend)" $STD pnpm --filter "web..." --filter smtp-server build
cp -r apps/web/.next/static apps/web/.next/standalone/apps/web/.next/
cp -r apps/web/public apps/web/.next/standalone/apps/web/
rm -rf apps/web/.next/cache
msg_ok "Built useSend"

if [[ -t 0 && ( -z "${var_github_id:-}" || -z "${var_github_secret:-}" ) ]]; then
  echo -e "${INFO}${YW} useSend has no local accounts; logging in needs a GitHub OAuth app.${CL}"
  echo -e "${TAB}Create one at https://github.com/settings/developers with this callback URL:"
  echo -e "${TAB}${BGN}http://${LOCAL_IP}:3000/api/auth/callback/github${CL}"
  if [[ -z "${var_github_id:-}" ]]; then
    read -t 300 -rp "${TAB3}GitHub Client ID (Enter to set it up later): " var_github_id || true
  fi
  if [[ -n "${var_github_id:-}" && -z "${var_github_secret:-}" ]]; then
    read -t 300 -rsp "${TAB3}GitHub Client Secret: " var_github_secret || true
    echo
  fi
fi

msg_info "Configuring useSend"
mkdir -p /opt/usesend_data
cat <<EOF >/opt/usesend_data/.env
PORT=3000
NEXTAUTH_URL=http://${LOCAL_IP}:3000
NEXTAUTH_SECRET=$(openssl rand -base64 32)
DATABASE_URL=postgresql://usesend:${PG_DB_PASS}@localhost:5432/usesend
REDIS_URL=redis://localhost:6379
SMTP_HOST=${LOCAL_IP}
SMTP_USER=usesend
# Sending goes through AWS SES: an IAM user with AmazonSESFullAccess and AmazonSNSFullAccess.
# The SES region and callback URL are set in the web UI under Admin after the first login.
AWS_DEFAULT_REGION=us-east-1
#AWS_ACCESS_KEY_ID=
#AWS_SECRET_ACCESS_KEY=
EOF
if [[ -n "${var_github_id:-}" && -n "${var_github_secret:-}" ]]; then
  cat <<EOF >>/opt/usesend_data/.env
GITHUB_ID=${var_github_id}
GITHUB_SECRET=${var_github_secret}
EOF
else
  cat <<EOF >>/opt/usesend_data/.env
# useSend has no local accounts. Create a GitHub OAuth app with the callback URL
# http://${LOCAL_IP}:3000/api/auth/callback/github, fill in the two lines below
# (or GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET, which needs an HTTPS domain), then run:
# systemctl enable --now usesend usesend-smtp
#GITHUB_ID=
#GITHUB_SECRET=
EOF
fi
chmod 600 /opt/usesend_data/.env
create_self_signed_cert "usesend"
msg_ok "Configured useSend"

msg_info "Migrating useSend Database"
set -a && source /opt/usesend_data/.env && set +a
$STD pnpm --filter web db:migrate-deploy
msg_ok "Migrated useSend Database"

msg_info "Creating useSend Services"
cat <<EOF >/etc/systemd/system/usesend.service
[Unit]
Description=useSend
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/usesend/apps/web/.next/standalone
EnvironmentFile=/opt/usesend_data/.env
ExecStart=/usr/bin/node apps/web/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/usesend-smtp.service
[Unit]
Description=useSend SMTP Proxy
After=network.target usesend.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/usesend/apps/smtp-server
Environment=USESEND_BASE_URL=http://127.0.0.1:3000
Environment=SMTP_AUTH_USERNAME=usesend
Environment=USESEND_API_KEY_PATH=/etc/ssl/usesend/usesend.key
Environment=USESEND_API_CERT_PATH=/etc/ssl/usesend/usesend.crt
ExecStart=/usr/bin/node dist/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
if [[ -n "${var_github_id:-}" && -n "${var_github_secret:-}" ]]; then
  systemctl enable -q --now usesend usesend-smtp
fi
msg_ok "Created useSend Services"

motd_ssh
customize
cleanup_lxc
