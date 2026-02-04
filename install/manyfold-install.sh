#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01 | Co-Author: SunFlowerOwl
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/manyfold3d/manyfold

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libarchive-dev \
  git \
  libmariadb-dev \
  redis-server \
  nginx \
  libassimp-dev
msg_ok "Installed Dependencies"

setup_imagemagick
PG_VERSION="16" setup_postgresql
PG_DB_NAME="manyfold" PG_DB_USER="manyfold" setup_postgresql_db
NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

fetch_and_deploy_gh_release "manyfold" "manyfold3d/manyfold" "tarball" "latest" "/opt/manyfold/app"

RUBY_INSTALL_VERSION=$(cat /opt/manyfold/app/.ruby-version)
RUBY_VERSION=${RUBY_INSTALL_VERSION} RUBY_INSTALL_RAILS="true" HOME=/home/manyfold setup_ruby

msg_info "Configuring Manyfold"
YARN_VERSION=$(grep '"packageManager":' /opt/manyfold/app/package.json | sed -E 's/.*"(yarn@[0-9\.]+)".*/\1/')
RELEASE=$(get_latest_github_release "manyfold3d/manyfold")
useradd -m -s /usr/bin/bash manyfold
cat <<EOF >/opt/manyfold/.env
export APP_VERSION=${RELEASE}
export GUID=1002
export PUID=1001
export PUBLIC_PORT=5000
export REDIS_URL=redis://127.0.0.1:6379/1
export DATABASE_ADAPTER=postgresql
export DATABASE_HOST=127.0.0.1
export DATABASE_USER=${PG_DB_USER}
export DATABASE_PASSWORD=${PG_DB_PASS}
export DATABASE_NAME=${PG_DB_NAME}
export DATABASE_CONNECTION_POOL=16
export MULTIUSER=enabled
export HTTPS_ONLY=false
export RAILS_ENV=production
EOF
cat <<EOF >/opt/manyfold/user_setup.sh
#!/bin/bash

source /opt/manyfold/.env
export PATH="/home/manyfold/.rbenv/bin:\$PATH"
eval "\$(/home/manyfold/.rbenv/bin/rbenv init - bash)"
cd /opt/manyfold/app
rbenv global $RUBY_INSTALL_VERSION
gem install bundler
bundle install
gem install sidekiq
gem install foreman
corepack enable yarn
rm -f /opt/manyfold/app/config/credentials.yml.enc
corepack prepare $YARN_VERSION --activate
corepack use $YARN_VERSION
export VISUAL="code --wait"
bin/rails credentials:edit
bin/rails db:migrate
bin/rails assets:precompile
EOF
$STD mkdir -p /opt/manyfold_data
msg_ok "Configured Manyfold"

msg_info "Installing Manyfold"
chown -R manyfold:manyfold {/home/manyfold,/opt/manyfold}
chmod +x /opt/manyfold/user_setup.sh
$STD npm install --global corepack
$STD sudo -u manyfold bash /opt/manyfold/user_setup.sh
rm -f /opt/manyfold/user_setup.sh
msg_ok "Installed Manyfold"

msg_info "Creating Services"
source /opt/manyfold/.env
export PATH="/home/manyfold/.rbenv/shims:/home/manyfold/.rbenv/bin:$PATH"
$STD foreman export systemd /etc/systemd/system -a manyfold -u manyfold -f /opt/manyfold/app/Procfile
for f in /etc/systemd/system/manyfold-*.service; do
  sed -i "s|/bin/bash -lc '|/bin/bash -lc 'source /opt/manyfold/.env \&\& |" "$f"
done
systemctl enable -q --now manyfold.target manyfold-rails.1 manyfold-default_worker.1 manyfold-performance_worker.1
cat <<EOF >/etc/nginx/sites-available/manyfold.conf
server {
    listen 80;
    server_name manyfold;
    root /opt/manyfold/app/public;

    location /cable {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        try_files \$uri/index.html \$uri @rails;
    }

    location @rails {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
ln -s /etc/nginx/sites-available/manyfold.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
