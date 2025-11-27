#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: onionrings29
# License: MIT | https://github.com/onionrings29/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rommapp/romm

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  make \
  gcc \
  g++ \
  libmariadb3 \
  libmariadb-dev \
  libpq-dev \
  libffi-dev \
  musl-dev \
  curl \
  ca-certificates \
  libmagic-dev \
  p7zip-full \
  tzdata \
  libbz2-dev \
  libssl-dev \
  libreadline-dev \
  libsqlite3-dev \
  zlib1g-dev \
  liblzma-dev \
  libncurses5-dev \
  libncursesw5-dev
msg_ok "Installed Dependencies"

NODE_VERSION="18.20.8" setup_nodejs
setup_uv

msg_info "Building RAHasher (for RetroAchievements)"
cd /tmp
git clone --recursive --branch 1.8.1 --depth 1 https://github.com/RetroAchievements/RALibretro.git
cd RALibretro
sed -i '22a #include <ctime>' ./src/Util.h
sed -i '6a #include <unistd.h>' \
  ./src/libchdr/deps/zlib-1.3.1/gzlib.c \
  ./src/libchdr/deps/zlib-1.3.1/gzread.c \
  ./src/libchdr/deps/zlib-1.3.1/gzwrite.c
$STD make HAVE_CHD=1 -f ./Makefile.RAHasher
cp ./bin64/RAHasher /usr/bin/RAHasher
chmod +x /usr/bin/RAHasher
cd /tmp
rm -rf RALibretro
msg_ok "Built RAHasher"

msg_info "Cloning ROMM Repository"
cd /opt
git clone https://github.com/rommapp/romm.git
cd romm
msg_ok "Cloned ROMM Repository"

msg_info "Installing Python Dependencies"
/usr/local/bin/uv python install 3.13
/usr/local/bin/uv sync --all-extras
msg_ok "Installed Python Dependencies"

msg_info "Installing Frontend Dependencies"
cd /opt/romm/frontend
$STD npm install
msg_ok "Installed Frontend Dependencies"

msg_info "Creating Environment Configuration"
mkdir -p /opt/romm_storage/library
mkdir -p /opt/romm_storage/resources
mkdir -p /opt/romm_storage/redis-data

cat <<EOF >/opt/romm/.env
# Database Configuration
DB_HOST=localhost
DB_NAME=romm
DB_USER=romm_user
DB_PASSWD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)

# ROMM Configuration
ROMM_HOST=0.0.0.0
ROMM_PORT=8080
ROMM_BASE_PATH=/romm

# Storage Paths
ROMM_DB_DRIVER=sqlite
LIBRARY_BASE_PATH=/opt/romm_storage/library
RESOURCES_BASE_PATH=/opt/romm_storage/resources
REDIS_DATA_DIR=/opt/romm_storage/redis-data

# Authentication
ENABLE_EXPERIMENTAL_REDIS=false
DISABLE_CSRF_PROTECTION=false
EOF

chmod 600 /opt/romm/.env
msg_ok "Created Environment Configuration"

msg_info "Creating Systemd Service"
cat <<EOF >/etc/systemd/system/romm.service
[Unit]
Description=ROMM ROM Manager
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/romm
EnvironmentFile=/opt/romm/.env
ExecStart=/opt/romm/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now romm
msg_ok "Created Systemd Service"

motd_ssh
customize
cleanup_lxc
