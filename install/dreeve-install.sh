#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dreeveapp/dreeve

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libsqlite3-0 \
  libcap2-bin \
  ca-certificates
msg_ok "Installed Dependencies"

# 1.13.0's php-cli shifts the script into argv[1], which breaks composer and bin/console (php/frankenphp#2690); unpin once 1.13.1 is out
fetch_and_deploy_gh_release "frankenphp" "php/frankenphp" "singlefile" "v1.12.7" "/opt/frankenphp" "frankenphp-linux-$(arch_resolve x86_64 aarch64)-gnu"
fetch_and_deploy_gh_release "dreeve" "dreeveapp/dreeve" "tarball"

msg_info "Providing php CLI"
cat <<'EOF' >/usr/local/bin/php
#!/usr/bin/env bash
exec /opt/frankenphp/frankenphp php-cli "$@"
EOF
chmod +x /usr/local/bin/php
msg_ok "Provided php CLI"

msg_info "Installing Composer"
curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
$STD /opt/frankenphp/frankenphp php-cli /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f /tmp/composer-setup.php
msg_ok "Installed Composer"

msg_info "Installing PHP Dependencies (Patience)"
cd /opt/dreeve
export COMPOSER_ALLOW_SUPERUSER=1
export APP_ENV=prod
$STD /opt/frankenphp/frankenphp php-cli /usr/local/bin/composer install --no-dev --optimize-autoloader --no-interaction --no-scripts
msg_ok "Installed PHP Dependencies"

msg_info "Configuring Dreeve"
mkdir -p /opt/dreeve_data /opt/dreeve/var/{cache,log}
DREEVE_PASSWORD=$(openssl rand -base64 18)
DREEVE_HASH=$(DREEVE_PASSWORD="$DREEVE_PASSWORD" /opt/frankenphp/frankenphp php-cli -r 'echo password_hash(getenv("DREEVE_PASSWORD"), PASSWORD_BCRYPT, ["cost" => 13]);')
[[ "$DREEVE_HASH" =~ ^\$2y\$ ]] || {
  msg_error "Could not generate the admin password hash"
  exit 1
}
cat <<EOF >/opt/dreeve/.env.local
APP_ENV=prod
APP_DEBUG=0
APP_SECRET=$(openssl rand -hex 32)
APP_URL=http://${LOCAL_IP}:8080
DATABASE_DIRECTORY=/opt/dreeve_data
ADMIN_USERNAME=admin
ADMIN_PASSWORD_HASH='${DREEVE_HASH}'
TZ=UTC

# Create an API application at https://www.strava.com/settings/api
STRAVA_CLIENT_ID=replace-me
STRAVA_CLIENT_SECRET=replace-me
STRAVA_REFRESH_TOKEN=replace-me
EOF
chmod 600 /opt/dreeve/.env.local

cat <<EOF >~/dreeve.creds
Dreeve Admin
Username: admin
Password: ${DREEVE_PASSWORD}
EOF
chmod 600 ~/dreeve.creds

cat <<EOF >/opt/dreeve/Caddyfile
{
	http_port 8080
	auto_https off

	frankenphp {
		num_threads 3
		worker {
			num 2
			file /opt/dreeve/public/index.php
		}
	}
}

:8080 {
	root /opt/dreeve/public
	encode zstd br gzip
	php_server
}
EOF
msg_ok "Configured Dreeve"

msg_info "Initializing Database"
cd /opt/dreeve
set -a
source /opt/dreeve/.env.local
set +a
$STD /opt/frankenphp/frankenphp php-cli bin/console app:db:migrate --no-interaction
$STD /opt/frankenphp/frankenphp php-cli bin/console assets:install public --no-interaction
$STD /opt/frankenphp/frankenphp php-cli bin/console cache:warmup --env=prod
msg_ok "Initialized Database"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/dreeve.service
[Unit]
Description=Dreeve
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/dreeve
EnvironmentFile=/opt/dreeve/.env.local
ExecStart=/opt/frankenphp/frankenphp run --config /opt/dreeve/Caddyfile
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now dreeve
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
