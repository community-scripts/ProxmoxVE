#!/usr/bin/env bash

# Copyright (c) 2021-2025 Community-Scripts ORG
# Author: tteck (tteckster) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nginxproxymanager.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt update
$STD apt -y install \
  ca-certificates \
  apache2-utils \
  logrotate \
  build-essential \
  git
msg_ok "Installed Dependencies"

msg_info "Installing Python Dependencies"
$STD apt install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  python3-cffi
msg_ok "Installed Python Dependencies"

msg_info "Setting up Certbot"
$STD python3 -m venv /opt/certbot
$STD /opt/certbot/bin/pip install --upgrade pip setuptools wheel
$STD /opt/certbot/bin/pip install certbot certbot-dns-cloudflare
ln -sf /opt/certbot/bin/certbot /usr/local/bin/certbot
msg_ok "Set up Certbot"

msg_info "Installing Openresty"
curl -fsSL "https://openresty.org/package/pubkey.gpg" | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg
cat <<'EOF' >/etc/apt/sources.list.d/openresty.sources
Types: deb
URIs: http://openresty.org/package/debian/
Suites: bookworm
Components: openresty
Signed-By: /etc/apt/trusted.gpg.d/openresty.gpg
EOF
$STD apt update
$STD apt -y install openresty
msg_ok "Installed Openresty"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

# RELEASE=$(curl -fsSL https://api.github.com/repos/NginxProxyManager/nginx-proxy-manager/releases/latest |
#  grep "tag_name" |
#  awk '{print substr($2, 3, length($2)-4) }')
RELEASE="2.13.4"

fetch_and_deploy_gh_release "nginxproxymanager" "NginxProxyManager/nginx-proxy-manager" "tarball" "v2.13.4"

msg_info "Setting up Environment"
ln -sf /usr/bin/python3 /usr/bin/python
ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx
ln -sf /usr/local/openresty/nginx/ /etc/nginx
sed -i "s|\"version\": \"2.0.0\"|\"version\": \"$RELEASE\"|" /opt/nginxproxymanager/backend/package.json
sed -i "s|\"version\": \"2.0.0\"|\"version\": \"$RELEASE\"|" /opt/nginxproxymanager/frontend/package.json
sed -i 's+^daemon+#daemon+g' /opt/nginxproxymanager/docker/rootfs/etc/nginx/nginx.conf
NGINX_CONFS=$(find /opt/nginxproxymanager -type f -name "*.conf")
for NGINX_CONF in $NGINX_CONFS; do
  sed -i 's+include conf.d+include /etc/nginx/conf.d+g' "$NGINX_CONF"
done

mkdir -p /var/www/html /etc/nginx/logs
cp -r /opt/nginxproxymanager/docker/rootfs/var/www/html/* /var/www/html/
cp -r /opt/nginxproxymanager/docker/rootfs/etc/nginx/* /etc/nginx/
cp /opt/nginxproxymanager/docker/rootfs/etc/letsencrypt.ini /etc/letsencrypt.ini
cp /opt/nginxproxymanager/docker/rootfs/etc/logrotate.d/nginx-proxy-manager /etc/logrotate.d/nginx-proxy-manager
ln -sf /etc/nginx/nginx.conf /etc/nginx/conf/nginx.conf
rm -f /etc/nginx/conf.d/dev.conf

mkdir -p /tmp/nginx/body \
  /run/nginx \
  /data/nginx \
  /data/custom_ssl \
  /data/logs \
  /data/access \
  /data/nginx/default_host \
  /data/nginx/default_www \
  /data/nginx/proxy_host \
  /data/nginx/redirection_host \
  /data/nginx/stream \
  /data/nginx/dead_host \
  /data/nginx/temp \
  /var/lib/nginx/cache/public \
  /var/lib/nginx/cache/private \
  /var/cache/nginx/proxy_temp

chmod -R 777 /var/cache/nginx
chown root /tmp/nginx

echo resolver "$(awk 'BEGIN{ORS=" "} $1=="nameserver" {print ($2 ~ ":")? "["$2"]": $2}' /etc/resolv.conf);" >/etc/nginx/conf.d/include/resolvers.conf

if [ ! -f /data/nginx/dummycert.pem ] || [ ! -f /data/nginx/dummykey.pem ]; then
  $STD openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/O=Nginx Proxy Manager/OU=Dummy Certificate/CN=localhost" -keyout /data/nginx/dummykey.pem -out /data/nginx/dummycert.pem
fi

mkdir -p /app/frontend/images
cp -r /opt/nginxproxymanager/backend/* /app
msg_ok "Set up Environment"

msg_info "Building Frontend"
export NODE_OPTIONS="--max_old_space_size=2048 --openssl-legacy-provider"
cd /opt/nginxproxymanager/frontend
# Replace node-sass with sass in package.json before installation
sed -E -i 's/"node-sass" *: *"([^"]*)"/"sass": "\1"/g' package.json
$STD yarn install --network-timeout 600000
$STD yarn build
cp -r /opt/nginxproxymanager/frontend/dist/* /app/frontend
cp -r /opt/nginxproxymanager/frontend/public/images/* /app/frontend/images
msg_ok "Built Frontend"

msg_info "Initializing Backend"
rm -rf /app/config/default.json
if [ ! -f /app/config/production.json ]; then
  cat <<'EOF' >/app/config/production.json
{
  "database": {
    "engine": "knex-native",
    "knex": {
      "client": "sqlite3",
      "connection": {
        "filename": "/data/database.sqlite"
      }
    }
  }
}
EOF
fi
cd /app
$STD yarn install --network-timeout 600000
msg_ok "Initialized Backend"

msg_info "Creating Service"
cat <<'EOF' >/lib/systemd/system/npm.service
[Unit]
Description=Nginx Proxy Manager
After=network.target
Wants=openresty.service

[Service]
Type=simple
Environment=NODE_ENV=production
ExecStartPre=-mkdir -p /tmp/nginx/body /data/letsencrypt-acme-challenge
ExecStart=/usr/bin/node index.js --abort_on_uncaught_exception --max_old_space_size=250
WorkingDirectory=/app
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Service"

msg_info "Starting Services"
sed -i 's/user npm/user root/g; s/^pid/#pid/g' /usr/local/openresty/nginx/conf/nginx.conf
sed -r -i 's/^([[:space:]]*)su npm npm/\1#su npm npm/g;' /etc/logrotate.d/nginx-proxy-manager
systemctl enable -q --now openresty
systemctl enable -q --now npm
msg_ok "Started Services"

motd_ssh
customize

msg_info "Cleaning up"
systemctl restart openresty
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
