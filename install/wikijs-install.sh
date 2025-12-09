#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/

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

NODE_VERSION="22" NODE_MODULE="yarn,node-gyp" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="wiki" PG_DB_USER="wikijs_user" PG_DB_EXTENSIONS="pg_trgm" setup_postgresql_db
fetch_and_deploy_gh_release "wikijs" "requarks/wiki" "prebuild" "latest" "/opt/wikijs" "wiki-js.tar.gz"

msg_info "Configuring Wiki.js"
mv /opt/wikijs/config.sample.yml /opt/wikijs/config.yml
sed -i -E 's|^( *user: ).*|\1'"$PG_DB_USER"'|' /opt/wikijs/config.yml
sed -i -E 's|^( *pass: ).*|\1'"$PG_DB_PASS"'|' /opt/wikijs/config.yml
msg_ok "Configured Wiki.js"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wikijs.service
[Unit]
Description=Wiki.js
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node server
Restart=always
User=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/wikijs

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wikijs
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
