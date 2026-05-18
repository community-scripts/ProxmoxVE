#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.docuseal.com/

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
  libssl-dev \
  libyaml-dev \
  libreadline-dev \
  zlib1g-dev \
  libffi-dev \
  libvips42 \
  libvips-dev \
  libheif1 \
  redis-server \
  fontconfig
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
RUBY_VERSION="4.0.1" RUBY_INSTALL_RAILS="false" HOME=/root setup_ruby
PG_VERSION="17" setup_postgresql
PG_DB_NAME="docuseal" PG_DB_USER="docuseal" setup_postgresql_db

msg_info "Downloading Fonts and PDFium"
mkdir -p /opt/fonts /usr/share/fonts/noto
ARCH=$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/')
curl -fsSL -o /opt/fonts/GoNotoKurrent-Regular.ttf \
  https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Regular.ttf
curl -fsSL -o /opt/fonts/GoNotoKurrent-Bold.ttf \
  https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Bold.ttf
curl -fsSL -o /opt/fonts/DancingScript-Regular.otf \
  https://github.com/impallari/DancingScript/raw/master/fonts/DancingScript-Regular.otf
ln -sf /opt/fonts/GoNotoKurrent-Regular.ttf /usr/share/fonts/noto/
ln -sf /opt/fonts/GoNotoKurrent-Bold.ttf /usr/share/fonts/noto/
$STD fc-cache -f
curl -fsSL -o /tmp/pdfium.tgz \
  "https://github.com/bblanchon/pdfium-binaries/releases/latest/download/pdfium-linux-${ARCH}.tgz"
mkdir -p /tmp/pdfium && tar -xzf /tmp/pdfium.tgz -C /tmp/pdfium
cp /tmp/pdfium/lib/libpdfium.so /usr/lib/libpdfium.so
rm -rf /tmp/pdfium /tmp/pdfium.tgz
msg_ok "Downloaded Fonts and PDFium"

fetch_and_deploy_gh_release "docuseal" "docusealco/docuseal" "tarball"

msg_info "Downloading Field Detection Model"
mkdir -p /opt/docuseal/tmp
curl -fsSL -o /opt/docuseal/tmp/model.onnx \
  "https://github.com/docusealco/fields-detection/releases/download/2.0.0/model_704_int8.onnx"
mkdir -p /opt/docuseal/public/fonts
ln -sf /opt/fonts/DancingScript-Regular.otf /opt/docuseal/public/fonts/DancingScript-Regular.otf
msg_ok "Downloaded Field Detection Model"

msg_info "Configuring DocuSeal"
SECRET_KEY=$(openssl rand -hex 64)
mkdir -p /opt/docuseal/data
cat <<EOF >/opt/docuseal/.env
RAILS_ENV=production
NODE_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
SECRET_KEY_BASE=${SECRET_KEY}
DATABASE_URL=postgresql://docuseal:${PG_DB_PASS}@127.0.0.1:5432/docuseal
REDIS_URL=redis://localhost:6379/0
WORKDIR=/opt/docuseal/data
VIPS_MAX_COORD=17000
EOF
msg_ok "Configured DocuSeal"

msg_info "Building Application"
cd /opt/docuseal
export PATH="/root/.rbenv/bin:/root/.rbenv/shims:${PATH}"
eval "$(rbenv init - bash)" 2>/dev/null || true
export RAILS_ENV=production
export NODE_ENV=production
export SECRET_KEY_BASE_DUMMY=1
set -a
source /opt/docuseal/.env
set +a
$STD bundle config set --local deployment 'true'
$STD bundle config set --local without 'development:test'
$STD bundle install -j"$(nproc)"
$STD yarn install --network-timeout 1000000
$STD ./bin/shakapacker
$STD bundle exec rails db:migrate
$STD bundle exec bootsnap precompile -j 1 --gemfile app/ lib/
msg_ok "Built Application"

msg_info "Enabling Redis"
systemctl enable -q --now redis-server
msg_ok "Enabled Redis"

msg_info "Creating docuseal User"
id docuseal &>/dev/null || useradd -u 2000 -M -s /usr/sbin/nologin -d /opt/docuseal docuseal
chmod o+x /root
chmod -R o+rX /root/.rbenv
chown -R docuseal:docuseal /opt/docuseal /opt/fonts
msg_ok "Created docuseal User"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/docuseal.service
[Unit]
Description=DocuSeal Web
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=docuseal
Group=docuseal
WorkingDirectory=/opt/docuseal
EnvironmentFile=/opt/docuseal/.env
Environment=HOME=/opt/docuseal
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=BUNDLE_GEMFILE=/opt/docuseal/Gemfile
Environment=BUNDLE_WITHOUT=development:test
ExecStart=/opt/docuseal/bin/bundle exec puma -C /opt/docuseal/config/puma.rb --dir /opt/docuseal -p 3000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/docuseal-sidekiq.service
[Unit]
Description=DocuSeal Sidekiq
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=docuseal
Group=docuseal
WorkingDirectory=/opt/docuseal
EnvironmentFile=/opt/docuseal/.env
Environment=HOME=/opt/docuseal
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=BUNDLE_GEMFILE=/opt/docuseal/Gemfile
Environment=BUNDLE_WITHOUT=development:test
ExecStart=/opt/docuseal/bin/bundle exec sidekiq
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now docuseal docuseal-sidekiq
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
