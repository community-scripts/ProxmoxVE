#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://rss-bridge.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y caddy patchelf
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" setup_php
setup_composer

fetch_and_deploy_gh_release "curl-impersonate" "lexiforest/curl-impersonate" "prebuild" "latest" "/usr/local/lib/curl-impersonate" "libcurl-impersonate-v*.$(arch_resolve x86_64-linux-gnu aarch64-linux-gnu).tar.gz"

fetch_and_deploy_gh_release "rss-bridge" "RSS-Bridge/rss-bridge" "tarball"

msg_info "Setting up RSS-Bridge"
cd /opt/rss-bridge
$STD composer install --no-dev --optimize-autoloader
cp config.default.ini.php config.ini.php
chown -R www-data:www-data /opt/rss-bridge
msg_ok "Set up RSS-Bridge"

msg_info "Configuring Caddy"
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/rss-bridge
    php_fastcgi unix//run/php/php${PHP_VER}-fpm.sock
    file_server
    encode gzip
}
EOF
usermod -aG www-data caddy
msg_ok "Configured Caddy"

if [[ -f /usr/local/lib/curl-impersonate/libcurl-impersonate.so ]]; then
  msg_info "Enabling curl-impersonate for PHP-FPM"
  patchelf --set-soname libcurl.so.4 /usr/local/lib/curl-impersonate/libcurl-impersonate.so
  mkdir -p /etc/systemd/system/php${PHP_VER}-fpm.service.d
  cat <<EOF >/etc/systemd/system/php${PHP_VER}-fpm.service.d/curl-impersonate.conf
[Service]
Environment=LD_PRELOAD=/usr/local/lib/curl-impersonate/libcurl-impersonate.so
EOF
  cat <<EOF >>/etc/php/${PHP_VER}/fpm/pool.d/www.conf
env[CURL_IMPERSONATE] = chrome142
EOF
  $STD systemctl daemon-reload
  safe_service_restart php${PHP_VER}-fpm
  msg_ok "Enabled curl-impersonate for PHP-FPM"
fi

systemctl enable -q --now php${PHP_VER}-fpm
systemctl restart caddy

motd_ssh
customize
cleanup_lxc
