#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nginxproxymanager.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv
NODE_VERSION="20" NODE_MODULE="yarn@latest" install_node_and_modules

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y \
  build-essential \
  make gcc g++ git curl \
  apache2-utils logrotate \
  libffi-dev
msg_ok "Installed Dependencies"

msg_info "Setting up certbot"
$STD apt-get install -y libaugeas0
$STD uv venv /opt/certbot/.venv
$STD /opt/certbot/.venv/bin/uv pip install certbot certbot-dns-cloudflare certbot-dns-multi
ln -sf /opt/certbot/.venv/bin/certbot /usr/bin/certbot
msg_ok "Set up certbot"

msg_info "Installing OpenResty"
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
curl -fsSL https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg
echo "deb http://openresty.org/package/debian $VERSION openresty" >/etc/apt/sources.list.d/openresty.list
$STD apt-get update
$STD apt-get install -y openresty
ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx
ln -sf /usr/local/openresty/nginx /etc/nginx
msg_ok "Installed OpenResty"

RELEASE=$(curl -fsSL https://api.github.com/repos/NginxProxyManager/nginx-proxy-manager/releases/latest | grep "tag_name" | awk -F'"' '{print $4}')
msg_info "Downloading Nginx Proxy Manager v${RELEASE}"
curl -fsSL "https://codeload.github.com/NginxProxyManager/nginx-proxy-manager/tar.gz/refs/tags/v${RELEASE}" | tar -xz
cd ./nginx-proxy-manager-${RELEASE}
msg_ok "Downloaded Nginx Proxy Manager"

msg_info "Setting up Nginx Proxy Manager"
sed -i "s|\"version\": \"0.0.0\"|\"version\": \"${RELEASE}\"|" backend/package.json frontend/package.json
sed -i 's|^daemon|#daemon|' docker/rootfs/etc/nginx/nginx.conf
find . -type f -name "*.conf" -exec sed -i 's|include conf.d|include /etc/nginx/conf.d|g' {} \;

mkdir -p /var/www/html /etc/nginx/logs
cp -r docker/rootfs/var/www/html/* /var/www/html/
cp -r docker/rootfs/etc/nginx/* /etc/nginx/
cp docker/rootfs/etc/letsencrypt.ini /etc/letsencrypt.ini
cp docker/rootfs/etc/logrotate.d/nginx-proxy-manager /etc/logrotate.d/nginx-proxy-manager
ln -sf /etc/nginx/nginx.conf /etc/nginx/conf/nginx.conf
rm -f /etc/nginx/conf.d/dev.conf
msg_ok "Set up Nginx Proxy Manager"

msg_info "Preparing Runtime Environment"
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
  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/O=Nginx Proxy Manager/OU=Dummy Certificate/CN=localhost" \
    -keyout /data/nginx/dummykey.pem \
    -out /data/nginx/dummycert.pem &>/dev/null
fi
msg_ok "Prepared Runtime Environment"

msg_info "Building Frontend"
cd ./frontend
$STD yarn install --frozen-lockfile
$STD yarn upgrade
$STD yarn run build
cp -r dist/* /app/frontend
cp -r app-images/* /app/frontend/images
msg_ok "Built Frontend"

msg_info "Initializing Backend"
cd ../backend
rm -rf /app/config/default.json
mkdir -p /app/config
cat <<EOF >/app/config/production.json
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
cd ..
mkdir -p /app/global /app/frontend/images
cp -r backend/* /app
cp -r global/* /app/global
cd /app
$STD yarn install --frozen-lockfile
msg_ok "Initialized Backend"

msg_info "Creating Systemd Service"
cat <<EOF >/etc/systemd/system/npm.service
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
msg_ok "Created Systemd Service"

motd_ssh
customize

msg_info "Starting Services"
sed -i 's/user npm/user root/g; s/^pid/#pid/' /usr/local/openresty/nginx/conf/nginx.conf
sed -r -i 's/^([[:space:]]*)su npm npm/\1#su npm npm/' /etc/logrotate.d/nginx-proxy-manager
sed -i 's/include-system-site-packages = false/include-system-site-packages = true/' /opt/certbot/.venv/pyvenv.cfg
systemctl enable -q --now openresty
systemctl enable -q --now npm
msg_ok "Started Services"

msg_info "Cleaning Up"
rm -rf ../nginx-proxy-manager-*
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
