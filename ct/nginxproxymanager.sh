#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 Community-Script ORG
# Author: tteck (tteckster) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nginxproxymanager.com/

APP="Nginx Proxy Manager"
var_tags="${var_tags:-proxy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /lib/systemd/system/npm.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ $(grep -E '^VERSION_ID=' /etc/os-release) == *"12"* ]]; then
    msg_error "Wrong Debian version detected!"
    msg_error "Please create a snapshot first. You must upgrade your LXC to Debian Trixie before updating. Visit: https://github.com/community-scripts/ProxmoxVE/discussions/7489"
    exit
  fi

  if command -v node &>/dev/null; then
    CURRENT_NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$CURRENT_NODE_VERSION" != "22" ]]; then
      systemctl stop openresty
      apt-get purge -y nodejs npm
      apt-get autoremove -y
      rm -rf /usr/local/bin/node /usr/local/bin/npm
      rm -rf /usr/local/lib/node_modules
      rm -rf ~/.npm
      rm -rf /root/.npm
    fi
  fi

  NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

  #RELEASE=$(curl -fsSL https://api.github.com/repos/NginxProxyManager/nginx-proxy-manager/releases/latest |
    #grep "tag_name" |
    #awk '{print substr($2, 3, length($2)-4) }')

  RELEASE="2.13.4"
  CLEAN_INSTALL=1 fetch_and_deploy_gh_release "nginxproxymanager" "NginxProxyManager/nginx-proxy-manager" "tarball" "v${RELEASE}" "/opt/nginxproxymanager"
  
  msg_info "Stopping Services"
  systemctl stop openresty
  systemctl stop npm
  msg_ok "Stopped Services"

  msg_info "Cleaning old files"
  $STD rm -rf /app \
    /var/www/html \
    /etc/nginx \
    /var/log/nginx \
    /var/lib/nginx \
    /var/cache/nginx
  msg_ok "Cleaned old files"

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

  msg_info "Updating Certbot"
  [ -f /etc/apt/trusted.gpg.d/openresty-archive-keyring.gpg ] && rm -f /etc/apt/trusted.gpg.d/openresty-archive-keyring.gpg
  [ -f /etc/apt/sources.list.d/openresty.list ] && rm -f /etc/apt/sources.list.d/openresty.list
  [ ! -f /etc/apt/trusted.gpg.d/openresty.gpg ] && curl -fsSL https://openresty.org/package/pubkey.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/openresty.gpg
  [ ! -f /etc/apt/sources.list.d/openresty.sources ] && cat <<'EOF' >/etc/apt/sources.list.d/openresty.sources
Types: deb
URIs: http://openresty.org/package/debian/
Suites: bookworm
Components: openresty
Signed-By: /etc/apt/trusted.gpg.d/openresty.gpg
EOF
  $STD apt update
  $STD apt -y install openresty
  if [ -d /opt/certbot ]; then
    $STD /opt/certbot/bin/pip install --upgrade pip setuptools wheel
    $STD /opt/certbot/bin/pip install --upgrade certbot certbot-dns-cloudflare
  fi
  msg_ok "Updated Certbot"

  msg_info "Starting Services"
  sed -i 's/user npm/user root/g; s/^pid/#pid/g' /usr/local/openresty/nginx/conf/nginx.conf
  sed -r -i 's/^([[:space:]]*)su npm npm/\1#su npm npm/g;' /etc/logrotate.d/nginx-proxy-manager
  systemctl enable -q --now openresty
  systemctl enable -q --now npm
  systemctl restart openresty
  msg_ok "Started Services"

  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:81${CL}"
