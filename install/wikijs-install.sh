#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/ | Github: https://github.com/requarks/wiki

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

NODE_VERSION="26" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="wiki" PG_DB_USER="wikijs_user" setup_postgresql_db
fetch_and_deploy_gh_release "wikijs" "requarks/wiki" "prebuild" "latest" "/opt/wikijs" "wiki-js.tar.gz"

msg_info "Installing Wiki.js Dependencies"
cd /opt/wikijs/backend
$STD npm ci --omit=dev
msg_ok "Installed Wiki.js Dependencies"

msg_info "Configuring Wiki.js"
mkdir -p /opt/wikijs_data
cp /opt/wikijs/config.sample.yml /opt/wikijs/config.yml
sed -i \
  -e "s|^  user: .*|  user: wikijs_user|" \
  -e "s|^  pass: .*|  pass: ${PG_DB_PASS}|" \
  -e "s|^  db: .*|  db: wiki|" \
  -e "s|^dataPath: .*|dataPath: /opt/wikijs_data|" \
  /opt/wikijs/config.yml
ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-16)
cat <<EOF >~/wikijs.creds
Wiki.js Admin
Email: admin@example.com
Password: ${ADMIN_PASS}
EOF
msg_ok "Configured Wiki.js"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wikijs.service
[Unit]
Description=Wiki.js
After=network.target postgresql.service

[Service]
Type=simple
ExecStart=/usr/bin/node --no-experimental-webstorage backend
Restart=always
User=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/wikijs

[Install]
WantedBy=multi-user.target
EOF
systemctl set-environment ADMIN_PASS="${ADMIN_PASS}"
systemctl enable -q --now wikijs
for _ in $(seq 60); do
  curl -fs -o /dev/null http://127.0.0.1:3000 && break
  sleep 2
done
systemctl unset-environment ADMIN_PASS
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
