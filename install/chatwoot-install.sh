#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.chatwoot.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  git \
  imagemagick \
  libpq-dev \
  libvips42 \
  pkg-config \
  redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="chatwoot_production" PG_DB_USER="chatwoot" PG_DB_EXTENSIONS="vector,pg_stat_statements" setup_postgresql_db

fetch_and_deploy_gh_release "chatwoot" "chatwoot/chatwoot" "tarball"

RUBY_VERSION=$(tr -d ' \n' </opt/chatwoot/.ruby-version)
RUBY_VERSION="${RUBY_VERSION}" RUBY_INSTALL_RAILS="false" setup_ruby
NODE_VERSION=$(grep -oP '"node":\s*"\K[0-9]+' /opt/chatwoot/package.json)
NODE_VERSION="${NODE_VERSION}" NODE_MODULE="pnpm" setup_nodejs
export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"

msg_info "Installing Application Dependencies"
cd /opt/chatwoot
$STD bundle config set --local without 'development test'
$STD bundle config set --local deployment 'true'
$STD bundle install
$STD pnpm install --frozen-lockfile
msg_ok "Installed Application Dependencies"

msg_info "Configuring Chatwoot"
SECRET_KEY_BASE=$(openssl rand -hex 64)
mkdir -p /opt/chatwoot/storage
cat <<EOF >/opt/chatwoot/.env
RAILS_ENV=production
NODE_ENV=production
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=${SECRET_KEY_BASE}
FRONTEND_URL=http://${LOCAL_IP}:3000
FORCE_SSL=false
ENABLE_ACCOUNT_SIGNUP=false

POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_DATABASE=${PG_DB_NAME}
POSTGRES_USERNAME=${PG_DB_USER}
POSTGRES_PASSWORD=${PG_DB_PASS}
REDIS_URL=redis://127.0.0.1:6379

ACTIVE_STORAGE_SERVICE=local
EOF
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=$(openssl rand -hex 32)
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=$(openssl rand -hex 32)
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=$(openssl rand -hex 32)
cat <<EOF >>/opt/chatwoot/.env
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=${ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY}
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=${ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY}
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=${ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT}
EOF
chmod 640 /opt/chatwoot/.env
msg_ok "Configured Chatwoot"

msg_info "Preparing Database"
RAILS_ENV=production $STD bundle exec rails db:chatwoot_prepare
msg_ok "Prepared Database"

msg_info "Precompiling Assets"
RAILS_ENV=production NODE_OPTIONS="--max-old-space-size=4096" $STD bundle exec rails assets:precompile
msg_ok "Precompiled Assets"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/chatwoot-web.service
[Unit]
Description=Chatwoot Web
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/chatwoot
EnvironmentFile=/opt/chatwoot/.env
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/root/.rbenv/shims/bundle exec rails server -p 3000 -e production
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/chatwoot-worker.service
[Unit]
Description=Chatwoot Worker
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/chatwoot
EnvironmentFile=/opt/chatwoot/.env
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/root/.rbenv/shims/bundle exec sidekiq -C config/sidekiq.yml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now chatwoot-web chatwoot-worker redis-server
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
