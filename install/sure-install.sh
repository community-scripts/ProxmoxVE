#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sure.am

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
  redis-server \
  pkg-config \
  libpq-dev \
  libvips
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "Sure" "we-promise/sure" "tarball" "latest" "/opt/sure"

PG_VERSION="$(sed -n '/postgres:/s/[^[:digit:]]*//p' /opt/sure/compose.example.yml)" setup_postgresql
PG_DB_NAME=sure_production PG_DB_USER=sure_user setup_postgresql_db
RUBY_VERSION="$(cat /opt/sure/.ruby-version)" RUBY_INSTALL_RAILS=false setup_ruby

msg_info "Building Sure"
cd /opt/sure
export RAILS_ENV=production
export BUNDLE_DEPLOYMENT=1
export BUNDLE_WITHOUT=development
$STD ./bin/bundle install
$STD ./bin/bundle exec bootsnap precompile --gemfile -j 0
$STD ./bin/bundle exec bootsnap precompile -j 0 app/ lib/
export SECRET_KEY_BASE_DUMMY=1 && $STD ./bin/rails assets:precompile
unset SECRET_KEY_BASE_DUMMY
msg_ok "Built Sure"

msg_info "Configuring Sure"
KEY="$(openssl rand -hex 64)"
mkdir -p /etc/sure
mv /opt/sure/.env.example /etc/sure/.env
sed -i -e "/^SECRET_KEY_BASE=/s/secret-value/${KEY}/" \
  -e 's/_KEY_BASE=.*$/&\n\nRAILS_FORCE_SSL=false \
\
# Change to true when using a reverse proxy \
RAILS_ASSUME_SSL=false/' \
  -e "/POSTGRES_PASSWORD=/s/postgres/${PG_DB_PASS}/" \
  -e "/POSTGRES_USER=/s/postgres/${PG_DB_USER}\\
POSTGRES_DB=${PG_DB_NAME}/" \
  -e "s|^APP_DOMAIN=|&${LOCAL_IP}|" /etc/sure/.env
msg_ok "Configured Sure"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/sure.service
[Unit]
Description=Sure Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/sure
Environment=RAILS_ENV=production
Environment=BUNDLE_DEPLOYMENT=1
Environment=BUNDLE_WITHOUT=development
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/bin:\$PATH
EnvironmentFile=/etc/sure/.env
ExecStartPre=/opt/sure/bin/rails db:prepare
ExecStart=/opt/sure/bin/rails server
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now sure
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
