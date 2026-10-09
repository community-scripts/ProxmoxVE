#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pglombardo/PasswordPusher

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  default-libmysqlclient-dev \
  git \
  libpq-dev \
  libsqlite3-dev \
  pkg-config
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

fetch_and_deploy_gh_release "passwordpusher" "pglombardo/PasswordPusher" "tarball"

RUBY_VERSION="$(cat /opt/passwordpusher/.ruby-version)" RUBY_INSTALL_RAILS="false" setup_ruby
export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"

msg_info "Installing Gem Dependencies"
cd /opt/passwordpusher
$STD bundle config set --local without 'development test'
$STD bundle config set --local deployment 'true'
$STD bundle install
msg_ok "Installed Gem Dependencies"

msg_info "Installing JS Dependencies"
$STD yarn install --frozen-lockfile
msg_ok "Installed JS Dependencies"

msg_info "Configuring PasswordPusher"
mkdir -p /opt/passwordpusher/storage/db
SECRET_KEY_BASE=$(bundle exec rails secret)
MASTER_KEY=$(openssl rand -hex 32)
cat <<EOF >/opt/passwordpusher/.env.production
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PWPUSH_MASTER_KEY=${MASTER_KEY}
PWP__FILES__STORAGE=local
RAILS_LOG_TO_STDOUT=true
PORT=5100
EOF
msg_ok "Configured PasswordPusher"

msg_info "Setting up Database"
RAILS_ENV=production $STD bundle exec rails db:setup
msg_ok "Set up Database"

msg_info "Precompiling Assets"
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 $STD bundle exec rails assets:precompile
msg_ok "Precompiled Assets"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/passwordpusher.service
[Unit]
Description=Password Pusher
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/passwordpusher
Environment=RAILS_ENV=production
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EnvironmentFile=/opt/passwordpusher/.env.production
ExecStart=/root/.rbenv/shims/bundle exec puma -C config/puma.rb -e production
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now passwordpusher
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
