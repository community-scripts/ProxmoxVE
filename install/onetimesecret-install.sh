#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Hai Tran (epiHATR)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://onetimesecret.com/ | Github: https://github.com/onetimesecret/onetimesecret

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
  libffi-dev \
  libgmp-dev \
  libpq-dev \
  libreadline-dev \
  libsodium23 \
  libsqlite3-dev \
  libssl-dev \
  libxml2-dev \
  libxslt1-dev \
  libyaml-dev \
  nginx \
  pkg-config \
  python3 \
  redis-server \
  zlib1g-dev
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "onetimesecret" "onetimesecret/onetimesecret" "tarball"

RUBY_VERSION=$(tr -d ' \n' </opt/onetimesecret/.ruby-version 2>/dev/null)
RUBY_VERSION="${RUBY_VERSION:-3.4.10}" setup_ruby

PNPM_VERSION=$(sed -n 's/.*"packageManager": "pnpm@\([^"]*\)".*/\1/p' /opt/onetimesecret/package.json)
NODE_VERSION=$(tr -d ' \n' </opt/onetimesecret/.nvmrc 2>/dev/null)
NODE_VERSION="${NODE_VERSION:-25}" NODE_MODULE="pnpm@${PNPM_VERSION:-11.1.2}" setup_nodejs

HOST_VALUE="${OTS_HOST:-$LOCAL_IP}"
SSL_VALUE="${OTS_SSL:-false}"
case "${SSL_VALUE,,}" in
1 | true | yes | on) SSL_VALUE="true" ;;
0 | false | no | off | "") SSL_VALUE="false" ;;
*)
  msg_error "Invalid OTS_SSL value '${OTS_SSL}' (use true/false)"
  exit 1
  ;;
esac

msg_info "Configuring Application"
systemctl enable -q --now redis-server
cd /opt/onetimesecret
$STD bash bin/setup init
sed -i \
  -e "s|^REDIS_URL=.*|REDIS_URL=redis://127.0.0.1:6379/0|" \
  -e "s|^HOST=.*|HOST=${HOST_VALUE//&/\\&}|" \
  -e "s|^SSL=.*|SSL=${SSL_VALUE}|" \
  /opt/onetimesecret/.env
if grep -q '^RACK_ENV=' /opt/onetimesecret/.env; then
  sed -i 's|^RACK_ENV=.*|RACK_ENV=production|' /opt/onetimesecret/.env
else
  echo "RACK_ENV=production" >>/opt/onetimesecret/.env
fi
if grep -q '^AUTHENTICATION_MODE=' /opt/onetimesecret/.env; then
  sed -i 's|^AUTHENTICATION_MODE=.*|AUTHENTICATION_MODE=simple|' /opt/onetimesecret/.env
else
  echo "AUTHENTICATION_MODE=simple" >>/opt/onetimesecret/.env
fi
if ! grep -q '^PORT=' /opt/onetimesecret/.env; then
  echo "PORT=3000" >>/opt/onetimesecret/.env
fi
chmod 600 /opt/onetimesecret/.env
mkdir -p /opt/onetimesecret/tmp/pids /opt/onetimesecret/log
msg_ok "Configured Application"

msg_info "Reconciling Application"
cd /opt/onetimesecret
$STD bash bin/setup reconcile
msg_ok "Reconciled Application"

msg_info "Building Frontend"
cd /opt/onetimesecret
$STD pnpm run build
msg_ok "Built Frontend"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/onetimesecret.service
[Unit]
Description=Onetime Secret Service
After=network.target redis-server.service
Requires=redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/onetimesecret
Environment=HOME=/root
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EnvironmentFile=/opt/onetimesecret/.env
ExecStart=/root/.rbenv/shims/bundle exec puma -C etc/puma.rb
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now onetimesecret
msg_ok "Created Service"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/onetimesecret
server {
  listen 80 default_server;
  server_name _;

  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
EOF
ln -sf /etc/nginx/sites-available/onetimesecret /etc/nginx/sites-enabled/onetimesecret
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
systemctl enable -q --now nginx
systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
