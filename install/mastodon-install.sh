#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mastodon/mastodon

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  imagemagick \
  libvips-tools \
  libpq-dev \
  libxslt1-dev \
  file \
  protobuf-compiler \
  pkg-config \
  autoconf \
  bison \
  build-essential \
  libssl-dev \
  libyaml-dev \
  libreadline-dev \
  zlib1g-dev \
  libffi-dev \
  libgdbm-dev \
  libidn-dev \
  libicu-dev \
  libjemalloc-dev \
  libjemalloc2 \
  redis-server \
  nginx
msg_ok "Installed Dependencies"

setup_ffmpeg
NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs
$STD corepack enable

PG_VERSION="17" setup_postgresql
PG_DB_NAME="mastodon_production" PG_DB_USER="mastodon" PG_DB_SKIP_ALTER_ROLE="true" setup_postgresql_db
$STD sudo -u postgres psql -c "ALTER USER mastodon CREATEDB;"

fetch_and_deploy_gh_release "mastodon" "mastodon/mastodon" "tarball"
sed -i "s/config.force_ssl = true/config.force_ssl = ENV.fetch('LOCAL_HTTPS', 'false') == 'true'/" /opt/mastodon/config/environments/production.rb
sed -i "s/https = Rails.env.production? || ENV\['LOCAL_HTTPS'\] == 'true'/https = ENV.fetch('LOCAL_HTTPS', 'false') == 'true'/" /opt/mastodon/config/initializers/1_hosts.rb

RUBY_VERSION="$(cat /opt/mastodon/.ruby-version)" RUBY_INSTALL_RAILS="false" setup_ruby
export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"

msg_info "Installing Ruby Dependencies"
cd /opt/mastodon
$STD bundle config set --local without 'development test'
$STD bundle config set --local deployment 'true'
$STD bundle install -j"$(nproc)"
msg_ok "Installed Ruby Dependencies"

msg_info "Installing Node.js Dependencies"
$STD yarn install
msg_ok "Installed Node.js Dependencies"

msg_info "Configuring Mastodon"
SECRET_KEY_BASE=$(RAILS_ENV=production bundle exec rails secret)
OTP_SECRET=$(RAILS_ENV=production bundle exec rails secret)

VAPID_OUTPUT=$(RAILS_ENV=production bundle exec rails mastodon:webpush:generate_vapid_key 2>/dev/null)
VAPID_PRIVATE_KEY=$(echo "$VAPID_OUTPUT" | grep "^VAPID_PRIVATE_KEY=" | cut -d= -f2-)
VAPID_PUBLIC_KEY=$(echo "$VAPID_OUTPUT" | grep "^VAPID_PUBLIC_KEY=" | cut -d= -f2-)

ENCRYPT_OUTPUT=$(RAILS_ENV=production bundle exec rails db:encryption:init 2>/dev/null)
AR_DET_KEY=$(echo "$ENCRYPT_OUTPUT" | grep "^ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=" | cut -d= -f2-)
AR_SALT=$(echo "$ENCRYPT_OUTPUT" | grep "^ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=" | cut -d= -f2-)
AR_PRIMARY=$(echo "$ENCRYPT_OUTPUT" | grep "^ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=" | cut -d= -f2-)

mkdir -p /opt/mastodon/public/system
cat <<EOF >/opt/mastodon/.env.production
LOCAL_DOMAIN=${LOCAL_IP}
LOCAL_HTTPS=false
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
DB_HOST=127.0.0.1
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=${PG_DB_PASS}
DB_PORT=5432
RAILS_ENV=production
NODE_ENV=production
RAILS_SERVE_STATIC_FILES=true
BIND=0.0.0.0
SECRET_KEY_BASE=${SECRET_KEY_BASE}
OTP_SECRET=${OTP_SECRET}
VAPID_PRIVATE_KEY=${VAPID_PRIVATE_KEY}
VAPID_PUBLIC_KEY=${VAPID_PUBLIC_KEY}
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=${AR_DET_KEY}
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=${AR_SALT}
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=${AR_PRIMARY}
SMTP_SERVER=
SMTP_PORT=587
SMTP_FROM_ADDRESS=notifications@${LOCAL_IP}
EOF
msg_ok "Configured Mastodon"

msg_info "Setting up Database"
RAILS_ENV=production $STD bundle exec rails db:setup
msg_ok "Set up Database"

msg_info "Precompiling Assets (Patience)"
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 $STD bundle exec rails assets:precompile
msg_ok "Precompiled Assets"

msg_info "Creating Admin Account"
if ! ADMIN_OUTPUT=$(EMAIL_DOMAIN_ALLOWLIST="${LOCAL_IP}" RAILS_ENV=production bundle exec bin/tootctl accounts create admin \
  --email "admin@${LOCAL_IP}" \
  --confirmed \
  --approve \
  --role Owner); then
  msg_error "Failed to create Mastodon admin account"
  exit 1
fi
ADMIN_PASS=$(echo "$ADMIN_OUTPUT" | sed -n 's/^New password: //p')
if [[ -z "$ADMIN_PASS" ]]; then
  msg_error "Failed to retrieve Mastodon admin password"
  exit 1
fi
RAILS_ENV=production $STD bundle exec bin/tootctl settings registrations approved
cat <<EOF > ~/mastodon.creds
  Mastodon Admin Credentials
  URL:      http://${LOCAL_IP}
  Email:    admin@${LOCAL_IP}
  Password: ${ADMIN_PASS}
EOF
msg_ok "Created Admin Account"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/mastodon-web.service
[Unit]
Description=mastodon-web
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mastodon
Environment=RAILS_ENV=production
Environment=PORT=3000
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/root/.rbenv/shims/bundle exec puma -C config/puma.rb
ExecReload=/bin/kill -SIGUSR1 \$MAINPID
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/mastodon-sidekiq.service
[Unit]
Description=mastodon-sidekiq
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mastodon
Environment=RAILS_ENV=production
Environment=DB_POOL=25
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/root/.rbenv/shims/bundle exec sidekiq -c 25
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/mastodon-streaming.service
[Unit]
Description=mastodon-streaming
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mastodon
Environment=NODE_ENV=production
Environment=PORT=4000
ExecStart=/usr/bin/node ./streaming
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mastodon-web mastodon-sidekiq mastodon-streaming
msg_ok "Created Services"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/mastodon
map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}

upstream mastodon_web {
  server 127.0.0.1:3000 fail_timeout=0;
}

upstream mastodon_streaming {
  server 127.0.0.1:4000 fail_timeout=0;
}

server {
  listen 80;
  server_name _;
  client_max_body_size 99m;
  root /opt/mastodon/public;

  gzip on;
  gzip_types text/plain application/json application/javascript text/css image/svg+xml;

  location / {
    try_files $uri @proxy;
  }

  location ~ ^/assets/ {
    add_header Cache-Control "public, max-age=2419200, must-revalidate";
    try_files $uri =404;
  }

  location ^~ /api/v1/streaming {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://mastodon_streaming;
    proxy_buffering off;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    tcp_nodelay on;
  }

  location @proxy {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://mastodon_web;
    proxy_buffering on;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
  }
}
EOF
systemctl enable -q --now redis-server
nginx_enable_site mastodon
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
