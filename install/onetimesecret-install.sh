#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://onetimesecret.com | Github: https://github.com/onetimesecret/onetimesecret

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

APP_ROOT="/var/lib/onetimesecret"
APP_DIR="${APP_ROOT}/app"
APP_USER="onetime"
APP_GROUP="onetime"
OTS_HOST_VALUE="${OTS_HOST:-${LOCAL_IP}}"
OTS_SSL_VALUE="${OTS_SSL:-false}"

run_app_as_user() {
  local cmd="$1"
  runuser -u "$APP_USER" -- env \
    HOME="$APP_ROOT" \
    LANG="$LANG" \
    LC_ALL="$LC_ALL" \
    AUTHENTICATION_MODE="simple" \
    REDIS_URL="redis://127.0.0.1:6379/0" \
    RACK_ENV="production" \
    NODE_ENV="production" \
    PATH="$APP_ROOT/.rbenv/shims:$APP_ROOT/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    bash -lc "cd \"$APP_DIR\" && eval \"\$($APP_ROOT/.rbenv/bin/rbenv init - bash)\" && ${cmd}"
}

ensure_foreman() {
  run_app_as_user 'if ! gem list -i foreman >/dev/null 2>&1; then gem install foreman --no-document && rbenv rehash; fi'
}

case "${OTS_SSL_VALUE,,}" in
1 | true | yes | on) OTS_SSL_VALUE="true" ;;
0 | false | no | off) OTS_SSL_VALUE="false" ;;
*)
  msg_error "Invalid OTS_SSL value '${OTS_SSL_VALUE}' (use true/false)"
  exit 1
  ;;
esac

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  ca-certificates \
  curl \
  git \
  jq \
  libffi-dev \
  libgmp-dev \
  libreadline-dev \
  libssl-dev \
  libxml2-dev \
  libxslt-dev \
  libyaml-dev \
  locales \
  nginx \
  redis-server \
  zlib1g-dev
msg_ok "Installed Dependencies"

if ! getent group "$APP_GROUP" >/dev/null 2>&1; then
  groupadd --system "$APP_GROUP"
fi
if ! id -u "$APP_USER" >/dev/null 2>&1; then
  useradd --system --gid "$APP_GROUP" --home-dir "$APP_ROOT" --create-home --shell /usr/sbin/nologin "$APP_USER"
fi
mkdir -p "$APP_DIR"

$STD systemctl enable -q --now redis-server
$STD sed -i \
  -e 's/^bind .*/bind 127.0.0.1 -::1/' \
  -e 's/^#\?protected-mode .*/protected-mode yes/' \
  /etc/redis/redis.conf
$STD systemctl restart redis-server

fetch_and_deploy_gh_release "onetimesecret" "onetimesecret/onetimesecret" "tarball" "latest" "$APP_DIR"

PNPM_VERSION="$(jq -r '.packageManager | split("@")[1]' "$APP_DIR/package.json")"
NODE_VERSION="25" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs
RUBY_VERSION="$(grep -E "^ruby " "$APP_DIR/Gemfile" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
RUBY_VERSION="${RUBY_VERSION:-3.4.7}" RUBY_INSTALL_RAILS="false" HOME="$APP_ROOT" setup_ruby
chown -R "$APP_USER:$APP_GROUP" "$APP_ROOT"
install -d -m 0750 -o "$APP_USER" -g "$APP_GROUP" "$APP_DIR/tmp" "$APP_DIR/log"

if locale -a 2>/dev/null | grep -qi '^en_US\.utf8$'; then
  export LANG="en_US.UTF-8"
else
  export LANG="C.UTF-8"
fi
export LC_ALL="${LANG}"

msg_info "Initializing OneTimeSecret"
$STD run_app_as_user "./install.sh init"
msg_ok "Initialized OneTimeSecret"

msg_info "Configuring Production Settings"
if ! grep -qE '^TRUSTED_PROXY_DEPTH=' "$APP_DIR/.env" 2>/dev/null; then
  echo "TRUSTED_PROXY_DEPTH=1" >>"$APP_DIR/.env"
fi
if ! grep -qE '^AUTHENTICATION_MODE=' "$APP_DIR/.env" 2>/dev/null; then
  echo "AUTHENTICATION_MODE=simple" >>"$APP_DIR/.env"
fi
if ! grep -qE '^PORT=' "$APP_DIR/.env" 2>/dev/null; then
  echo "PORT=3000" >>"$APP_DIR/.env"
fi
if ! grep -qE '^PUMA_WORKERS=' "$APP_DIR/.env" 2>/dev/null; then
  echo "PUMA_WORKERS=2" >>"$APP_DIR/.env"
fi
if ! grep -qE '^PUMA_MIN_THREADS=' "$APP_DIR/.env" 2>/dev/null; then
  echo "PUMA_MIN_THREADS=1" >>"$APP_DIR/.env"
fi
if ! grep -qE '^PUMA_MAX_THREADS=' "$APP_DIR/.env" 2>/dev/null; then
  echo "PUMA_MAX_THREADS=8" >>"$APP_DIR/.env"
fi
sed -i \
  -e "s|^HOST=.*|HOST=${OTS_HOST_VALUE}|" \
  -e "s|^SSL=.*|SSL=${OTS_SSL_VALUE}|" \
  -e "s|^REDIS_URL=.*|REDIS_URL='redis://127.0.0.1:6379/0'|" \
  -e 's|^RACK_ENV=.*|RACK_ENV=production|' \
  -e 's|^NODE_ENV=.*|NODE_ENV=production|' \
  -e 's|^TRUSTED_PROXY_DEPTH=.*|TRUSTED_PROXY_DEPTH=1|' \
  -e 's|^AUTHENTICATION_MODE=.*|AUTHENTICATION_MODE=simple|' \
  "$APP_DIR/.env"
sed -i 's|bind "tcp://0.0.0.0:#{port}"|bind "tcp://127.0.0.1:#{port}"|' "$APP_DIR/etc/puma.rb"
chown -R "$APP_USER:$APP_GROUP" "$APP_ROOT"
chmod 600 "$APP_DIR/.env"
msg_ok "Configured Production Settings"

msg_info "Building Frontend"
$STD run_app_as_user "pnpm run build"
msg_ok "Built Frontend"

msg_info "Installing Procfile Runner"
$STD ensure_foreman
msg_ok "Installed Procfile Runner"

msg_info "Creating Service"
cat <<'EOF' >/etc/default/onetimesecret
# Optional overrides for OneTimeSecret (see /var/lib/onetimesecret/app/.env)
EOF

cat <<EOF >/etc/systemd/system/onetimesecret-web.service
[Unit]
Description=OneTime Secret Web Server (Puma)
Documentation=https://docs.onetimesecret.com/en/self-hosting/
After=network.target redis-server.service
Requires=network.target redis-server.service

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${APP_DIR}
Environment=HOME=${APP_ROOT}
Environment=PATH=${APP_ROOT}/.rbenv/shims:${APP_ROOT}/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=LANG=${LANG}
Environment=LC_ALL=${LC_ALL}
EnvironmentFile=-/etc/default/onetimesecret
ExecStartPre=/bin/bash -lc 'source ${APP_DIR}/.env.sh && foreman check -f ${APP_DIR}/Procfile.production'
ExecStart=/bin/bash -lc 'source ${APP_DIR}/.env.sh && exec foreman start -f ${APP_DIR}/Procfile.production'
TimeoutStopSec=30
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=full
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true
LockPersonality=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
RestrictRealtime=true
UMask=0027
ReadWritePaths=${APP_ROOT}

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now onetimesecret-web
msg_ok "Created Service"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/onetimesecret.conf
upstream onetimesecret {
    server 127.0.0.1:3000;
    keepalive 8;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    access_log /var/log/nginx/onetimesecret.access.log;
    error_log /var/log/nginx/onetimesecret.error.log warn;
    server_tokens off;

    client_max_body_size 10M;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location = /nginx-health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 "ok";
    }

    location ~ /\.(?!well-known) {
        deny all;
    }

    location / {
        proxy_pass http://onetimesecret;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header Connection "";
        proxy_redirect off;
        proxy_buffering off;
        proxy_connect_timeout 5s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
}
EOF
ln -sf /etc/nginx/sites-available/onetimesecret.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
systemctl enable -q --now nginx
$STD systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
