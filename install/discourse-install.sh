#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.discourse.org/

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
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libyaml-dev \
  imagemagick \
  gsfonts \
  brotli \
  nginx \
  redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
NODE_VERSION="24" setup_nodejs
RUBY_VERSION="3.4.4" setup_ruby

msg_info "Configuring PostgreSQL for Discourse"
DISCOURSE_DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
PG_HBA=$(find /etc/postgresql -name pg_hba.conf 2>/dev/null | head -n1)
sed -i 's/^local\s\+all\s\+all\s\+peer$/local   all             all                                     md5/' "$PG_HBA"
$STD systemctl restart postgresql
PG_DB_NAME="discourse" PG_DB_USER="discourse" PG_DB_PASS="$DISCOURSE_DB_PASS" PG_DB_EXTENSIONS="vector" setup_postgresql_db
msg_ok "Configured PostgreSQL for Discourse"

msg_info "Configuring Discourse"
DISCOURSE_SECRET_KEY=$(openssl rand -hex 64)
$STD git clone --depth 1 https://github.com/discourse/discourse.git /opt/discourse
cd /opt/discourse
cat <<EOF >/opt/discourse/.env
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
SECRET_KEY_BASE=${DISCOURSE_SECRET_KEY}
DISCOURSE_DB_HOST=/var/run/postgresql
DISCOURSE_DB_PORT=5432
DISCOURSE_DB_NAME=discourse
DISCOURSE_DB_USERNAME=discourse
DISCOURSE_DB_PASSWORD=${DISCOURSE_DB_PASS}
DISCOURSE_REDIS_URL=redis://localhost:6379
DISCOURSE_DEVELOPER_EMAILS=admin@discourse.local
DISCOURSE_HOSTNAME=${LOCAL_IP}
DISCOURSE_SMTP_ADDRESS=localhost
DISCOURSE_SMTP_PORT=25
DISCOURSE_SMTP_AUTHENTICATION=none
DISCOURSE_NOTIFICATION_EMAIL=noreply@${LOCAL_IP}
DISCOURSE_SKIP_NEW_ACCOUNT_EMAIL=true
APP_ROOT=/opt/discourse
EOF

mkdir -p /opt/discourse/tmp/sockets /opt/discourse/tmp/pids /opt/discourse/log
chown -R root:root /opt/discourse
chmod 755 /opt/discourse
msg_ok "Configured Discourse"

msg_info "Installing Discourse Dependencies"
$STD systemctl enable --now redis-server
cd /opt/discourse
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - bash)" 2>/dev/null || true
export RAILS_ENV=production
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
$STD corepack enable
$STD bundle config set --local deployment true
$STD bundle config set --local without 'test development'
$STD bundle install
$STD pnpm install
msg_ok "Installed Discourse Dependencies"

msg_info "Setting Up Database"
cd /opt/discourse
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - bash)" 2>/dev/null || true
export RAILS_ENV=production
set -a
source /opt/discourse/.env
set +a
$STD bundle exec rails db:migrate
$STD bundle exec rails db:seed
msg_ok "Set Up Database"

msg_info "Creating Admin Account"
ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)
$STD bundle exec rails runner "
user = User.new(email: 'admin@discourse.local', username: 'admin', password: '${ADMIN_PASS}')
user.active = true
user.admin = true
user.approved = true
user.save!(validate: false)
user.activate
user.grant_admin!
user.change_trust_level!(TrustLevel[4])
SiteSetting.has_login_hint = false
SiteSetting.wizard_enabled = false
"
cat <<EOF >~/discourse.creds
  Discourse Credentials
  Admin Username: admin
  Admin Email: admin@discourse.local
  Admin Password: ${ADMIN_PASS}
  Database Password: ${DISCOURSE_DB_PASS}
EOF
msg_ok "Created Admin Account"

msg_info "Building Discourse Assets"
cd /opt/discourse
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - bash)" 2>/dev/null || true
export RAILS_ENV=production
set -a && source /opt/discourse/.env && set +a
$STD bundle exec rails assets:precompile
msg_ok "Built Discourse Assets"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/discourse.service
[Unit]
Description=Discourse Forum
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/discourse
EnvironmentFile=/opt/discourse/.env
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/root/.rbenv/shims/bundle exec pitchfork -c config/pitchfork.conf.rb
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/discourse-sidekiq.service
[Unit]
Description=Discourse Sidekiq
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/discourse
EnvironmentFile=/opt/discourse/.env
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/root/.rbenv/shims/bundle exec sidekiq -q critical -q default -q low -q ultra_low
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now discourse discourse-sidekiq
msg_ok "Created Services"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/discourse
server {
  listen 80 default_server;
  server_name _;
  root /opt/discourse/public;

  client_max_body_size 100M;
  proxy_busy_buffers_size 512k;
  proxy_buffers 4 512k;

  location /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public,immutable;
  }

  location /uploads/ {
    expires 1h;
  }

  location / {
    try_files \$uri @discourse;
  }

  location @discourse {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Accel-Mapping /opt/discourse/public/=/downloads/;
  }
}
EOF
nginx_enable_site discourse
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
