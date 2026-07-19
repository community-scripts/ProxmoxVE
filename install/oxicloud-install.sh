#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DioCrafts/OxiCloud

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="oxicloud" PG_DB_USER="oxicloud" setup_postgresql_db
fetch_and_deploy_gh_release "OxiCloud" "DioCrafts/OxiCloud" "tarball" "latest" "/opt/oxicloud"
TOOLCHAIN="$(grep -oP 'FROM\s+rust:\K[0-9]+\.[0-9]+(\.[0-9]+)?' /opt/oxicloud/Dockerfile | head -1)"
RUST_TOOLCHAIN="${TOOLCHAIN:-stable}" setup_rust

msg_info "Building Frontend SPA"
cd /opt/oxicloud/frontend
$STD npm ci
$STD npm run build
msg_ok "Built Frontend SPA"

msg_info "Building OxiCloud (Patience)"
cd /opt/oxicloud
export DATABASE_URL="postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}"
export RUSTFLAGS="-C target-cpu=native"
RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
CARGO_JOBS=$((RAM_MB / 2560))
[[ $CARGO_JOBS -lt 1 ]] && CARGO_JOBS=1
[[ $CARGO_JOBS -gt $(nproc) ]] && CARGO_JOBS=$(nproc)
$STD cargo build --release -j "$CARGO_JOBS" --bin oxicloud --bin migrate-nfc-filenames
mv target/release/oxicloud /usr/local/bin/oxicloud
mv target/release/migrate-nfc-filenames /usr/local/bin/migrate-nfc-filenames
rm -rf /opt/oxicloud/static
mv /opt/oxicloud/static-dist /opt/oxicloud/static
rm -rf /opt/oxicloud/target /opt/oxicloud/frontend/node_modules
msg_ok "Built OxiCloud"

msg_info "Configuring OxiCloud"
mkdir -p {/mnt/oxicloud,/etc/oxicloud}
sed -e 's|OXICLOUD_STORAGE_PATH=.*|OXICLOUD_STORAGE_PATH=/mnt/oxicloud|' \
  -e 's|OXICLOUD_SERVER_HOST=.*|OXICLOUD_SERVER_HOST=0.0.0.0|' \
  -e 's|OXICLOUD_STATIC_PATH=.*|OXICLOUD_STATIC_PATH=/opt/oxicloud/static|' \
  -e "s|^#OXICLOUD_BASE_URL=.*|OXICLOUD_BASE_URL=http://${LOCAL_IP}:8086|" \
  -e "s|OXICLOUD_DB_CONNECTION_STRING=.*|OXICLOUD_DB_CONNECTION_STRING=${DATABASE_URL}|" \
  -e "s|^DATABASE_URL=.*|DATABASE_URL=${DATABASE_URL}|" \
  -e "s|^#OXICLOUD_JWT_SECRET=.*|OXICLOUD_JWT_SECRET=$(openssl rand -hex 32)|" \
  /opt/oxicloud/example.env >/etc/oxicloud/.env
chmod 600 /etc/oxicloud/.env
msg_ok "Configured OxiCloud"

msg_info "Creating OxiCloud Service"
cat <<EOF >/etc/systemd/system/oxicloud.service
[Unit]
Description=OxiCloud Service
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/oxicloud
EnvironmentFile=/etc/oxicloud/.env
ExecStart=/usr/local/bin/oxicloud
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now oxicloud
msg_ok "Created OxiCloud Service"

motd_ssh
customize
cleanup_lxc
