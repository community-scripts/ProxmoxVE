#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get -y install \
  sudo \
  mc \
  curl \
  gnupg \
  make \
  gcc \
  g++ \
  ca-certificates \
  apache2-utils \
  logrotate \
  build-essential \
  git
msg_ok "Installed Dependencies"

msg_info "Installing Python Dependencies"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  python3-cffi \
  python3-certbot \
  python3-certbot-dns-cloudflare
$STD pip3 install certbot-dns-multi
$STD python3 -m venv /opt/certbot/
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Installed Python Dependencies"

VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"

msg_info "Installing Openresty"
wget -qO - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty-archive-keyring.gpg
echo -e "deb http://openresty.org/package/debian bullseye openresty" >/etc/apt/sources.list.d/openresty.list
$STD apt-get update
$STD apt-get -y install openresty
msg_ok "Installed Openresty"

msg_info "Installing Node.js"
$STD bash <(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh)
source ~/.bashrc
$STD nvm install 16.20.2
ln -sf /root/.nvm/versions/node/v16.20.2/bin/node /usr/bin/node
msg_ok "Installed Node.js"

msg_info "Installing pnpm"
$STD npm install -g pnpm@8.15
msg_ok "Installed pnpm"

RELEASE=$(curl -s https://api.github.com/repos/NginxProxyManager/nginx-proxy-manager/releases/latest |
  grep "tag_name" |
  awk '{print substr($2, 3, length($2)-4) }')

read -r -p "Would you like to install an older version (v2.10.4)? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Downloading Nginx Proxy Manager v2.10.4"
  wget -q https://codeload.github.com/NginxProxyManager/nginx-proxy-manager/tar.gz/v2.10.4 -O - | tar -xz
  cd ./nginx-proxy-manager-2.10.4
  msg_ok "Downloaded Nginx Proxy Manager v2.10.4"
else
  msg_info "Downloading Nginx Proxy Manager v${RELEASE}"
  wget -q https://codeload.github.com/NginxProxyManager/nginx-proxy-manager/tar.gz/v${RELEASE} -O - | tar -xz
  cd ./nginx-proxy-manager-${RELEASE}
  msg_ok "Downloaded Nginx Proxy Manager v${RELEASE}"
fi
msg_info "Setting up Environment"
ln -sf /usr/bin/python3 /usr/bin/python
ln -sf /usr/bin/certbot /opt/certbot/bin/certbot
ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx
ln -sf /usr/local/openresty/nginx/ /etc/nginx
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"2.10.4\"|" backend/package.json
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"2.10.4\"|" frontend/package.json
else
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"$RELEASE\"|" backend/package.json
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"$RELEASE\"|" frontend/package.json
fi
sed -i 's|"fork-me": ".*"|"fork-me": "Proxmox VE Helper-Scripts"|' frontend/js/i18n/messages.json
sed -i "s|https://github.com.*source=nginx-proxy-manager|https://helper-scripts.com|g" frontend/js/app/ui/footer/main.ejs
sed -i 's+^daemon+#daemon+g' docker/rootfs/etc/nginx/nginx.conf
NGINX_CONFS=$(find "$(pwd)" -type f -name "*.conf")
for NGINX_CONF in $NGINX_CONFS; do
  sed -i 's+include conf.d+include /etc/nginx/conf.d+g' "$NGINX_CONF"
done

mkdir -p /var/www/html /etc/nginx/logs
cp -r docker/rootfs/var/www/html/* /var/www/html/
cp -r docker/rootfs/etc/nginx/* /etc/nginx/
cp docker/rootfs/etc/letsencrypt.ini /etc/letsencrypt.ini
cp docker/rootfs/etc/logrotate.d/nginx-proxy-manager /etc/logrotate.d/nginx-proxy-manager
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
  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/O=Nginx Proxy Manager/OU=Dummy Certificate/CN=localhost" -keyout /data/nginx/dummykey.pem -out /data/nginx/dummycert.pem &>/dev/null
fi

mkdir -p /app/global /app/frontend/images
cp -r backend/* /app
cp -r global/* /app/global
msg_ok "Set up Enviroment"

msg_info "Building Frontend"
cd ./frontend
$STD pnpm install
$STD pnpm upgrade
$STD pnpm run build
cp -r dist/* /app/frontend
cp -r app-images/* /app/frontend/images
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
$STD pnpm install
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

motd_ssh
customize

msg_info "Starting Services"
sed -i 's/user npm/user root/g; s/^pid/#pid/g' /usr/local/openresty/nginx/conf/nginx.conf
sed -r -i 's/^([[:space:]]*)su npm npm/\1#su npm npm/g;' /etc/logrotate.d/nginx-proxy-manager
sed -i 's/include-system-site-packages = false/include-system-site-packages = true/g' /opt/certbot/pyvenv.cfg
systemctl enable -q --now openresty
systemctl enable -q --now npm
msg_ok "Started Services"

msg_info "Cleaning up"
rm -rf ../nginx-proxy-manager-*
systemctl restart openresty
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
