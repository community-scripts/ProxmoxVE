#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: CrazyWolf13, MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nginxproxymanager.com/ | Github: https://github.com/NginxProxyManager/nginx-proxy-manager

APP="Nginx Proxy Manager"
var_tags="${var_tags:-proxy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
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

  if command -v node &>/dev/null; then
    CURRENT_NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$CURRENT_NODE_VERSION" != "22" ]]; then
      systemctl stop openresty
      $STD apt purge -y nodejs npm
      $STD apt autoremove -y
      rm -rf /usr/local/bin/node /usr/local/bin/npm
      rm -rf /usr/local/lib/node_modules
      rm -rf ~/.npm
      rm -rf /root/.npm
    fi
  fi

  NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

  if dpkg -s openresty &>/dev/null 2>&1; then
    msg_info "Migrating from packaged OpenResty to source"
    rm -f /etc/apt/trusted.gpg.d/openresty-archive-keyring.gpg /etc/apt/trusted.gpg.d/openresty.gpg
    rm -f /etc/apt/sources.list.d/openresty.list /etc/apt/sources.list.d/openresty.sources
    $STD apt purge -y openresty
    $STD apt autoremove -y
    rm -f ~/.openresty
    msg_ok "Migrated from packaged OpenResty to source"
  fi

  local pcre_pkg="libpcre3-dev"
  if grep -qE 'VERSION_ID="1[3-9]"' /etc/os-release 2>/dev/null; then
    pcre_pkg="libpcre2-dev"
  fi
  $STD apt install -y build-essential "$pcre_pkg" libssl-dev zlib1g-dev

  if check_for_gh_release "openresty" "openresty/openresty"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "openresty" "openresty/openresty" "prebuild" "${CHECK_UPDATE_RELEASE}" "/opt/openresty" "openresty-*.tar.gz"

    msg_info "Building OpenResty"
    cd /opt/openresty
    $STD ./configure \
      --with-http_v2_module \
      --with-http_realip_module \
      --with-http_stub_status_module \
      --with-http_ssl_module \
      --with-http_sub_module \
      --with-http_auth_request_module \
      --with-pcre-jit \
      --with-stream \
      --with-stream_ssl_module
    $STD make -j"$(nproc)"
    $STD make install
    rm -rf /opt/openresty
    cat <<'EOF' >/lib/systemd/system/openresty.service
[Unit]
Description=The OpenResty Application Platform
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=-/bin/mkdir -p /tmp/nginx/body /run/nginx
ExecStartPre=/usr/local/openresty/nginx/sbin/nginx -t
ExecStart=/usr/local/openresty/nginx/sbin/nginx -g 'daemon off;'

[Install]
WantedBy=multi-user.target
EOF
    sed -i 's/user npm/user root/g; s/^pid/#pid/g' /usr/local/openresty/nginx/conf/nginx.conf
    systemctl daemon-reload
    systemctl unmask openresty 2>/dev/null || true
    systemctl restart openresty
    msg_ok "Built OpenResty"
  fi

  cd /root
  if [ -d /opt/certbot ]; then
    msg_info "Updating Certbot"
    $STD /opt/certbot/bin/pip install --upgrade pip setuptools wheel
    $STD /opt/certbot/bin/pip install --upgrade certbot certbot-dns-cloudflare
    msg_ok "Updated Certbot"
  fi

  if check_for_gh_release "nginxproxymanager" "NginxProxyManager/nginx-proxy-manager"; then
    msg_info "Stopping Services"
    systemctl stop openresty
    systemctl stop npm
    msg_ok "Stopped Services"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "nginxproxymanager" "NginxProxyManager/nginx-proxy-manager" "tarball" "${CHECK_UPDATE_RELEASE}" "/opt/nginxproxymanager"

    msg_info "Cleaning old files"
    $STD rm -rf /app \
      /var/www/html \
      /etc/nginx \
      /var/log/nginx \
      /var/lib/nginx \
      /var/cache/nginx
    msg_ok "Cleaned old files"

    local RELEASE="${CHECK_UPDATE_RELEASE#v}"
    msg_info "Setting up Environment"
    ln -sf /usr/bin/python3 /usr/bin/python
    ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx
    ln -sf /usr/local/openresty/nginx/ /etc/nginx
    sed -i "0,/\"version\": \"[^\"]*\"/s|\"version\": \"[^\"]*\"|\"version\": \"$RELEASE\"|" /opt/nginxproxymanager/backend/package.json
    sed -i "0,/\"version\": \"[^\"]*\"/s|\"version\": \"[^\"]*\"|\"version\": \"$RELEASE\"|" /opt/nginxproxymanager/frontend/package.json
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
    sed -E -i 's/"node-sass" *: *"([^"]*)"/"sass": "\1"/g' package.json
    $STD yarn install --network-timeout 600000
    $STD yarn locale-compile
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
      "client": "better-sqlite3",
      "connection": {
        "filename": "/data/database.sqlite"
      },
      "useNullAsDefault": true
    }
  }
}
EOF
    fi
    sed -i 's/"client": "sqlite3"/"client": "better-sqlite3"/' /app/config/production.json
    cd /app
    $STD yarn install --network-timeout 600000
    msg_ok "Initialized Backend"

    msg_info "Starting Services"
    sed -i 's/user npm/user root/g; s/^pid/#pid/g' /usr/local/openresty/nginx/conf/nginx.conf
    sed -r -i 's/^([[:space:]]*)su npm npm/\1#su npm npm/g;' /etc/logrotate.d/nginx-proxy-manager
    systemctl daemon-reload
    systemctl enable -q --now openresty
    systemctl enable -q --now npm
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:81${CL}"
