#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/netalertx/NetAlertX

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
  sqlite3 \
  arp-scan \
  nmap \
  fping \
  nbtscan \
  traceroute \
  mtr-tiny \
  iw \
  snmp \
  dnsutils \
  net-tools \
  avahi-utils \
  libwww-perl \
  usbutils \
  psmisc \
  wget \
  zip \
  cron
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="curl,sqlite3" setup_php
export UV_PYTHON_INSTALL_DIR="/opt/uv-python"
PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "netalertx" "netalertx/NetAlertX" "tarball"

msg_info "Setting up NetAlertX"
cd /opt/netalertx
$STD uv venv --python 3.13 .venv
$STD uv pip install --python .venv/bin/python -r requirements.txt
ln -sfn /opt/netalertx/install/production-filesystem/services /opt/netalertx/services
ln -sfn /opt/netalertx /app
echo "v$(cat ~/.netalertx)" >/opt/netalertx/.VERSION
date +%s >/opt/netalertx/front/buildtimestamp.txt
mkdir -p /opt/netalertx_data/{config,db,log/plugins,api,tmp}
touch /opt/netalertx_data/log/{app.log,execution_queue.log,app_front.log,app.php_errors.log,stderr.log,db_is_locked.log}
install -m 600 /opt/netalertx/back/app.conf /opt/netalertx_data/config/app.conf
cp /opt/netalertx/back/app.db /opt/netalertx_data/db/app.db
NETALERTX_PASSWORD=$(random_password)
sed -i "s|^TIMEZONE=.*|TIMEZONE='$(timedatectl show -p Timezone --value 2>/dev/null || echo Etc/UTC)'|" /opt/netalertx_data/config/app.conf
cat <<EOF >>/opt/netalertx_data/config/app.conf
ARPSCAN_ARGS='arp-scan --ignoredups --retry=6'
NMAPDEV_ARGS='nmap --privileged -sn -PR -oX - '
SETPWD_enable_password=True
SETPWD_password='$(echo -n "$NETALERTX_PASSWORD" | sha256sum | awk '{print $1}')'
EOF
cat <<EOF >/opt/netalertx_data/.env
NETALERTX_PASSWORD=${NETALERTX_PASSWORD}
NETALERTX_APP=/opt/netalertx
NETALERTX_DATA=/opt/netalertx_data
NETALERTX_CONFIG=/opt/netalertx_data/config
NETALERTX_DB=/opt/netalertx_data/db
NETALERTX_API=/opt/netalertx_data/api
NETALERTX_LOG=/opt/netalertx_data/log
NETALERTX_TMP=/opt/netalertx_data/tmp
SYSTEM_SERVICES_RUN_TMP=/opt/netalertx_data/tmp
VENDORSPATH_NEWEST=/opt/netalertx_data/tmp/ieee-oui.txt
LOG_EXECUTION_QUEUE=/opt/netalertx_data/log/execution_queue.log
PYTHONPATH=/opt/netalertx:/opt/netalertx/server:/opt/netalertx/server/plugins
PATH=/opt/netalertx/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PYTHONUNBUFFERED=1
NMAP_PRIVILEGED=1
EOF
chmod 600 /opt/netalertx_data/.env
chown -R www-data:www-data /opt/netalertx_data
msg_ok "Set up NetAlertX"

msg_info "Configuring PHP-FPM and Nginx"
cat <<EOF >/etc/php/8.4/fpm/pool.d/netalertx.conf
[netalertx]
user = www-data
group = www-data
listen = /run/php/netalertx.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
env[NETALERTX_CONFIG] = /opt/netalertx_data/config
env[NETALERTX_DB] = /opt/netalertx_data/db
env[NETALERTX_API] = /opt/netalertx_data/api
env[NETALERTX_LOG] = /opt/netalertx_data/log
php_admin_value[memory_limit] = 256M
EOF
systemctl restart php8.4-fpm
cat <<'EOF' >/etc/nginx/sites-available/netalertx
map "$http_referer|$http_host" $sec_legacy {
    "~^https?://(?<ref_host>[^/:]+)(?::\d+)?/.*\|\k<ref_host>(?::\d+)?$" "TRUSTED";
    default "UNTRUSTED";
}
map $http_sec_fetch_site $is_trusted {
    "same-origin" "TRUSTED";
    ""            $sec_legacy;
    default       "UNTRUSTED";
}
server {
    listen 20211 default_server;
    large_client_header_buffers 4 16k;
    root /opt/netalertx/front;
    index index.php;
    add_header X-Forwarded-Prefix "/app" always;

    location /server/ {
        error_page 403 /403_internal.html;
        if ($is_trusted != "TRUSTED") {
            return 403;
        }
        rewrite ^/server/(.*)$ /$1 break;
        proxy_pass http://127.0.0.1:20212;
        proxy_buffering off;
        proxy_cache off;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        client_max_body_size 50m;
        proxy_read_timeout 3600s;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~* \.php$ {
        add_header Cache-Control "no-store";
        fastcgi_pass unix:/run/php/netalertx.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME $fastcgi_script_name;
        fastcgi_read_timeout 600;
    }
}
EOF
nginx_enable_site "netalertx"
msg_ok "Configured PHP-FPM and Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/netalertx.service
[Unit]
Description=NetAlertX Backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/netalertx
EnvironmentFile=/opt/netalertx_data/.env
AmbientCapabilities=CAP_NET_RAW CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/opt/netalertx/.venv/bin/python3 -m server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/cron.d/netalertx
* * * * * www-data LOG_EXECUTION_QUEUE=/opt/netalertx_data/log/execution_queue.log /opt/netalertx/services/scripts/cron_script.sh >/dev/null 2>&1
EOF
systemctl enable -q --now netalertx
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
