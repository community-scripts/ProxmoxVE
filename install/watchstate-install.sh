#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/arabcoders/watchstate

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  redis-server \
  ripgrep \
  sqlite3
msg_ok "Installed Dependencies"

PHP_VERSION="8.5" PHP_FPM="YES" setup_php
setup_composer
setup_ffmpeg
NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
fetch_and_deploy_gh_release "watchstate" "arabcoders/watchstate" "tarball" "latest" "/opt/watchstate" "" "v"

msg_info "Building WatchState"
cd /opt/watchstate
sed -i "s/'version' => 'dev-master'/'version' => 'v$(cat ~/.watchstate)'/" config/config.php
$STD composer install --no-dev --optimize-autoloader --no-interaction
cd /opt/watchstate/frontend
$STD bun install --frozen-lockfile --production
NODE_ENV=production $STD bun run generate
mv /opt/watchstate/frontend/exported /opt/watchstate/public/exported
rm -rf /opt/watchstate/frontend/node_modules /opt/watchstate/frontend/.nuxt
msg_ok "Built WatchState"

msg_info "Configuring WatchState"
# loaded first by CLI, worker and php-fpm alike; the default data dir is /opt/watchstate/var, which every update wipes
cat <<EOF >/opt/watchstate/.env
WS_DATA_PATH=/opt/watchstate_data
EOF
$STD php /opt/watchstate/bin/console db:migrate --execute
$STD php /opt/watchstate/bin/console system:apikey
chown -R www-data:www-data /opt/watchstate_data
msg_ok "Configured WatchState"

msg_info "Configuring Nginx"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/watchstate
server {
    listen 8080;
    server_name _;
    root /opt/watchstate/public;
    index index.php;
    client_max_body_size 100M;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }

    location ~ \.php\$ {
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 600;
    }
}
EOF
nginx_enable_site "watchstate"
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/watchstate-worker.service
[Unit]
Description=WatchState Worker
After=network.target redis-server.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/watchstate
ExecStart=/usr/bin/php /opt/watchstate/bin/console system:worker -v
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now watchstate-worker
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
