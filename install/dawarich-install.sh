#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Freika/dawarich

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
  libpq-dev \
  libgeos-dev \
  libyaml-dev \
  libffi-dev \
  libssl-dev \
  libjemalloc2 \
  imagemagick \
  libmagickwand-dev \
  libvips-dev \
  cmake \
  redis-server \
  nginx
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="postgis-3" setup_postgresql
PG_DB_NAME="dawarich_db" PG_DB_USER="dawarich" PG_DB_EXTENSIONS="postgis" setup_postgresql_db

fetch_and_deploy_gh_release "dawarich" "Freika/dawarich" "tarball" "latest" "/opt/dawarich/app"

msg_info "Setting up Directories"
mkdir -p /opt/dawarich/app/{storage,log,tmp/pids,tmp/cache,tmp/sockets}
msg_ok "Set up Directories"

msg_info "Configuring Environment"
SECRET_KEY_BASE=$(openssl rand -hex 64)
RELEASE=$(get_latest_github_release "Freika/dawarich")
cat <<EOF >/opt/dawarich/.env
RAILS_ENV=production
SECRET_KEY_BASE=${SECRET_KEY_BASE}
DATABASE_HOST=localhost
DATABASE_USERNAME=${PG_DB_USER}
DATABASE_PASSWORD=${PG_DB_PASS}
DATABASE_NAME=${PG_DB_NAME}
REDIS_URL=redis://127.0.0.1:6379/0
BACKGROUND_PROCESSING_CONCURRENCY=10
APPLICATION_HOST=${LOCAL_IP}
APPLICATION_HOSTS=${LOCAL_IP},localhost
TIME_ZONE=UTC
DISABLE_TELEMETRY=true
APP_VERSION=${RELEASE}
EOF
msg_ok "Configured Environment"

NODE_VERSION="22" setup_nodejs
RUBY_VERSION=$(cat /opt/dawarich/app/.ruby-version 2>/dev/null || echo "3.4.6")
RUBY_VERSION=${RUBY_VERSION} RUBY_INSTALL_RAILS="false" setup_ruby

msg_info "Installing Dawarich"
cd /opt/dawarich/app
source /root/.profile
export PATH="/root/.rbenv/shims:/root/.rbenv/bin:$PATH"
eval "$(/root/.rbenv/bin/rbenv init - bash)"
set -a && source /opt/dawarich/.env && set +a
$STD gem install bundler
$STD bundle config set --local deployment 'true'
$STD bundle config set --local without 'development test'
$STD bundle install
if [[ -f /opt/dawarich/package.json ]]; then
  cd /opt/dawarich
  $STD npm install
  cd /opt/dawarich/app
elif [[ -f /opt/dawarich/app/package.json ]]; then
  $STD npm install
fi
$STD bundle exec rake assets:precompile
$STD bundle exec rails db:prepare
$STD bundle exec rake data:migrate
msg_ok "Installed Dawarich"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/dawarich-web.service
[Unit]
Description=Dawarich Web Server
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/dawarich/app
EnvironmentFile=/opt/dawarich/.env
ExecStart=/root/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/dawarich-worker.service
[Unit]
Description=Dawarich Sidekiq Worker
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/dawarich/app
EnvironmentFile=/opt/dawarich/.env
ExecStart=/root/.rbenv/shims/bundle exec sidekiq -C config/sidekiq.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now redis-server dawarich-web dawarich-worker
msg_ok "Created Services"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/dawarich.conf
upstream dawarich {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name _;

    root /opt/dawarich/app/public;
    client_max_body_size 100M;

    location ~ ^/(assets|packs)/ {
        expires max;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }

    location / {
        try_files \$uri @rails;
    }

    location @rails {
        proxy_pass http://dawarich;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect off;
        proxy_buffering off;
    }
}
EOF
ln -sf /etc/nginx/sites-available/dawarich.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl enable -q --now nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
