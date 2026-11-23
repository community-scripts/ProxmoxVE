#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Budibase/budibase

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
  python3 \
  nginx \
  redis-server
msg_ok "Installed Dependencies"

JAVA_VERSION="8" setup_java
NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

msg_info "Installing Apache CouchDB"
COUCHDB_PASS=$(random_password)
COUCHDB_COOKIE=$(openssl rand -hex 32)
debconf-set-selections <<EOF
couchdb couchdb/mode select standalone
couchdb couchdb/bindaddress string 127.0.0.1
couchdb couchdb/cookie string ${COUCHDB_COOKIE}
couchdb couchdb/adminpass password ${COUCHDB_PASS}
couchdb couchdb/adminpass_again password ${COUCHDB_PASS}
EOF
setup_deb822_repo \
  "couchdb" \
  "https://couchdb.apache.org/repo/keys.asc" \
  "https://apache.jfrog.io/artifactory/couchdb-deb" \
  "$(get_os_info codename)" \
  "main"
DEBIAN_FRONTEND=noninteractive $STD apt install -y couchdb
mkdir -p /opt/budibase_data/{couch/dbs,couch/views,search,sqs,minio}
chown -R couchdb:couchdb /opt/budibase_data/couch
# CouchDB writes the hashed admin password to the last ini file, so this one sorts before 10-admins.ini to have it replace the plaintext there
cat <<EOF >/opt/couchdb/etc/local.d/00-budibase.ini
[couchdb]
database_dir = /opt/budibase_data/couch/dbs
view_index_dir = /opt/budibase_data/couch/views

[chttpd_auth]
timeout = 7200
EOF
chown couchdb:couchdb /opt/couchdb/etc/local.d/00-budibase.ini
systemctl restart couchdb
for _ in {1..30}; do
  curl -fs http://127.0.0.1:5984/_up >/dev/null && break
  sleep 2
done
$STD curl -fsS -X PUT -u "admin:${COUCHDB_PASS}" http://127.0.0.1:5984/_users
$STD curl -fsS -X PUT -u "admin:${COUCHDB_PASS}" http://127.0.0.1:5984/_replicator
msg_ok "Installed Apache CouchDB"

# Budibase's database image pins Clouseau 2.25.0 on Java 8; 3.x needs Java 21 and a different config format
fetch_and_deploy_gh_release "clouseau" "cloudant-labs/clouseau" "prebuild" "2.25.0" "/opt/clouseau" "clouseau-2.25.0-dist.zip"
fetch_and_deploy_gh_release "silo_s3" "pgsty/silo" "prebuild" "latest" "/opt/silo" "silo_*_linux_$(arch_resolve).tar.gz"
fetch_and_deploy_gh_release "budibase" "Budibase/budibase" "tarball"

msg_info "Building Budibase"
cd /opt/budibase
$STD yarn install --frozen-lockfile
CI=true $STD yarn build:apps
$STD yarn cache clean
msg_ok "Built Budibase"

msg_info "Configuring Budibase"
REDIS_PASS=$(random_password)
sed -i "s/^# requirepass .*/requirepass ${REDIS_PASS}/" /etc/redis/redis.conf
systemctl restart redis-server
cat <<EOF >/opt/clouseau/clouseau.ini
[clouseau]
name=clouseau@127.0.0.1
cookie=${COUCHDB_COOKIE}
dir=/opt/budibase_data/search
max_indexes_open=500
EOF
cat <<EOF >/opt/budibase_data/.env
NODE_ENV=production
NODE_OPTIONS=--no-node-snapshot
SELF_HOSTED=1
BUDIBASE_ENVIRONMENT=PRODUCTION
BUDIBASE_VERSION=$(cat ~/.budibase)
SERVER_TOP_LEVEL_PATH=/opt/budibase/packages/server
APP_PORT=4001
WORKER_PORT=4002
CLUSTER_PORT=80
APPS_URL=http://127.0.0.1:4001
WORKER_URL=http://127.0.0.1:4002
ACCOUNT_PORTAL_URL=https://account.budibase.app
COUCH_DB_URL=http://admin:${COUCHDB_PASS}@127.0.0.1:5984
COUCH_DB_SQL_URL=http://127.0.0.1:4984
REDIS_URL=127.0.0.1:6379
REDIS_PASSWORD=${REDIS_PASS}
MINIO_URL=http://127.0.0.1:9000
MINIO_ACCESS_KEY=$(random_password 20)
MINIO_SECRET_KEY=$(random_password 40)
MINIO_BROWSER=off
JWT_SECRET=$(openssl rand -hex 32)
INTERNAL_API_KEY=$(openssl rand -hex 32)
API_ENCRYPTION_KEY=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
EOF
chmod 600 /opt/budibase_data/.env
msg_ok "Configured Budibase"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/budibase-clouseau.service
[Unit]
Description=Budibase Clouseau Search
After=couchdb.service
Requires=couchdb.service
PartOf=couchdb.service

[Service]
Type=simple
WorkingDirectory=/opt/clouseau
ExecStart=/usr/bin/java -server -Xmx1G -Dsun.net.inetaddr.ttl=30 -Dsun.net.inetaddr.negative.ttl=30 -XX:+ExitOnOutOfMemoryError -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -classpath /opt/clouseau/* com.cloudant.clouseau.Main /opt/clouseau/clouseau.ini
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/budibase-sqs.service
[Unit]
Description=Budibase SQS
After=couchdb.service
Requires=couchdb.service

[Service]
Type=simple
WorkingDirectory=/opt/budibase/hosting/couchdb/sqs/$(arch_resolve "x86" "arm")
ExecStart=/opt/budibase/hosting/couchdb/sqs/$(arch_resolve "x86" "arm")/sqs --server http://127.0.0.1:5984 --data-dir /opt/budibase_data/sqs --bind-address=127.0.0.1 --max-threads=20
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/budibase-silo.service
[Unit]
Description=Budibase Silo Object Storage
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/budibase_data/.env
# ~/.silo is the version file of the Silo release, so Silo's config directory moves out of /root
Environment=HOME=/opt/budibase_data
ExecStart=/opt/silo/silo server /opt/budibase_data/minio --address 127.0.0.1:9000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/budibase-server.service
[Unit]
Description=Budibase App Server
After=network.target couchdb.service redis-server.service budibase-sqs.service budibase-silo.service
Requires=couchdb.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/budibase/packages/server
EnvironmentFile=/opt/budibase_data/.env
ExecStart=/usr/bin/node --enable-source-maps /opt/budibase/packages/server/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/budibase-worker.service
[Unit]
Description=Budibase Worker
After=network.target couchdb.service redis-server.service budibase-silo.service
Requires=couchdb.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/budibase/packages/worker
EnvironmentFile=/opt/budibase_data/.env
ExecStart=/usr/bin/node --enable-source-maps /opt/budibase/packages/worker/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now budibase-clouseau budibase-sqs budibase-silo budibase-worker budibase-server
msg_ok "Created Services"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/budibase
limit_req_zone $binary_remote_addr zone=budibase_api:10m rate=50r/s;
limit_req_zone $binary_remote_addr zone=budibase_webhooks:10m rate=10r/s;
limit_req_status 429;

map $http_upgrade $budibase_connection_upgrade {
  default "upgrade";
}

server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;
  client_max_body_size 1000m;
  ignore_invalid_headers off;
  proxy_buffering off;
  proxy_set_header Host $host;

  location = /health {
    proxy_pass http://127.0.0.1:4002/health;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location /app {
    proxy_buffering on;
    proxy_buffer_size 16k;
    proxy_buffers 8 32k;
    proxy_pass http://127.0.0.1:4001;
  }

  location /embed {
    rewrite /embed/(.*) /app/$1 break;
    proxy_pass http://127.0.0.1:4001;
    proxy_redirect off;
    proxy_set_header x-budibase-embed "true";
    add_header x-budibase-embed "true";
  }

  location = / {
    proxy_pass http://127.0.0.1:4001;
  }

  location = /builder/apps {
    return 301 $scheme://$http_host/apps;
  }

  location ~ ^/builder/portal/apps(/.*)?$ {
    return 301 $scheme://$http_host/builder/portal/workspaces$1;
  }

  location ~ ^/builder/app(/.*)?$ {
    return 301 $scheme://$http_host/builder/workspace$1;
  }

  location ~ ^/(builder|app_) {
    proxy_buffering on;
    proxy_buffer_size 16k;
    proxy_buffers 16 32k;
    proxy_busy_buffers_size 64k;
    proxy_http_version 1.1;
    proxy_set_header Connection $budibase_connection_upgrade;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:4001;
  }

  location ~ ^/api/(system|admin|global)/ {
    proxy_buffering on;
    proxy_buffer_size 16k;
    proxy_buffers 4 32k;
    proxy_pass http://127.0.0.1:4002;
  }

  location /worker/ {
    proxy_pass http://127.0.0.1:4002;
    rewrite ^/worker/(.*)$ /$1 break;
  }

  location /api/backups/ {
    limit_req zone=budibase_api burst=20 nodelay;
    proxy_read_timeout 1800s;
    proxy_connect_timeout 1800s;
    proxy_send_timeout 1800s;
    proxy_http_version 1.1;
    proxy_set_header Connection $budibase_connection_upgrade;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:4001;
  }

  location /api/webhooks/ {
    limit_req zone=budibase_webhooks burst=200 nodelay;
    proxy_read_timeout 120s;
    proxy_connect_timeout 120s;
    proxy_send_timeout 120s;
    proxy_http_version 1.1;
    proxy_set_header Connection $budibase_connection_upgrade;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:4001;
  }

  location /api/ {
    limit_req zone=budibase_api burst=20 nodelay;
    proxy_read_timeout 120s;
    proxy_connect_timeout 120s;
    proxy_send_timeout 120s;
    proxy_buffering on;
    proxy_buffer_size 16k;
    proxy_buffers 8 32k;
    proxy_http_version 1.1;
    proxy_set_header Connection $budibase_connection_upgrade;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:4001;
  }

  location /db/ {
    proxy_pass http://127.0.0.1:5984;
    rewrite ^/db/(.*)$ /$1 break;
  }

  location /socket/ {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_cache_bypass $http_upgrade;
    proxy_pass http://127.0.0.1:4001;
  }

  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $http_host;
    proxy_connect_timeout 300;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    chunked_transfer_encoding off;
    proxy_pass http://127.0.0.1:9000;
  }

  # Budibase signs object URLs for the host "minio-service", so the object store must see that host
  location /files/signed/ {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host minio-service;
    proxy_connect_timeout 300;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    chunked_transfer_encoding off;
    proxy_pass http://127.0.0.1:9000;
    rewrite ^/files/signed/(.*)$ /$1 break;
  }

  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;
}
EOF
nginx_enable_site "budibase"
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
