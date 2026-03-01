#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dedicatedcode/reitti

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  redis-server \
  rabbitmq-server \
  libpq-dev \
  zstd \
  nginx
msg_ok "Installed Dependencies"

JAVA_VERSION="25" setup_java
PG_VERSION="17" PG_MODULES="postgis" setup_postgresql
PG_DB_NAME="reitti_db" PG_DB_USER="reitti" PG_DB_EXTENSIONS="postgis" setup_postgresql_db

msg_info "Configuring RabbitMQ"
RABBIT_USER="reitti"
RABBIT_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
RABBIT_VHOST="/"
$STD rabbitmqctl add_user "$RABBIT_USER" "$RABBIT_PASS"
$STD rabbitmqctl add_vhost "$RABBIT_VHOST"
$STD rabbitmqctl set_permissions -p "$RABBIT_VHOST" "$RABBIT_USER" ".*" ".*" ".*"
$STD rabbitmqctl set_user_tags "$RABBIT_USER" administrator
{
  echo ""
  echo "Reitti Credentials"
  echo "RabbitMQ User: $RABBIT_USER"
  echo "RabbitMQ Password: $RABBIT_PASS"
} >>~/reitti.creds
msg_ok "Configured RabbitMQ"

USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "reitti" "dedicatedcode/reitti" "singlefile" "latest" "/opt/reitti" "reitti-app.jar"
mv /opt/reitti/reitti-*.jar /opt/reitti/reitti.jar
USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "photon" "komoot/photon" "singlefile" "latest" "/opt/photon" "photon-0*.jar"
mv /opt/photon/photon-*.jar /opt/photon/photon.jar

msg_info "Installing Nginx Tile Cache"
mkdir -p /var/cache/nginx/tiles
cat <<EOF >/etc/nginx/nginx.conf
user www-data;

events {
  worker_connections 1024;
}
http {
  proxy_cache_path /var/cache/nginx/tiles levels=1:2 keys_zone=tiles:10m max_size=1g inactive=30d use_temp_path=off;
  server {
    listen 80;
    location / {
      proxy_pass https://tile.openstreetmap.org/;
      proxy_set_header Host tile.openstreetmap.org;
      proxy_set_header User-Agent "Reitti/1.0";
      proxy_cache tiles;
      proxy_cache_valid 200 30d;
      proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
    }
  }
}
EOF
chown -R www-data:www-data /var/cache/nginx
chmod -R 750 /var/cache/nginx
systemctl restart nginx
msg_info "Installed Nginx Tile Cache"

msg_info "Creating Reitti Configuration-File"
mkdir -p /opt/reitti/data
cat <<EOF >/opt/reitti/application.properties
# Reitti Server Base URI
reitti.server.advertise-uri=http://127.0.0.1:8080

# PostgreSQL Database Connection
spring.datasource.url=jdbc:postgresql://127.0.0.1:5432/$PG_DB_NAME
spring.datasource.username=$PG_DB_USER
spring.datasource.password=$PG_DB_PASS
spring.datasource.driver-class-name=org.postgresql.Driver

# Flyway Database Migrations
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.baseline-on-migrate=true

# RabbitMQ (Message Queue)
spring.rabbitmq.host=127.0.0.1
spring.rabbitmq.port=5672
spring.rabbitmq.username=$RABBIT_USER
spring.rabbitmq.password=$RABBIT_PASS

# Redis (Cache)
spring.data.redis.host=127.0.0.1
spring.data.redis.port=6379

# Server Port
server.port=8080

# Optional: Logging & Performance
logging.level.root=INFO
spring.jpa.hibernate.ddl-auto=none
spring.datasource.hikari.maximum-pool-size=10

# OIDC / Security Settings
reitti.security.oidc.registration.enabled=false

# Photon (Geocoding)
PHOTON_BASE_URL=http://127.0.0.1:2322
PROCESSING_WAIT_TIME=15
PROCESSING_BATCH_SIZE=1000
PROCESSING_WORKERS_PER_QUEUE=4-16

# Disable potentially dangerous features unless needed
DANGEROUS_LIFE=false

# Tiles Cache
reitti.ui.tiles.cache.url=http://127.0.0.1
EOF
msg_ok "Created Configuration-File for Reitti"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/reitti.service
[Unit]
Description=Reitti
After=network.target postgresql.service redis-server.service rabbitmq-server.service photon.service
Wants=postgresql.service redis-server.service rabbitmq-server.service photon.service

[Service]
Type=simple
WorkingDirectory=/opt/reitti/
ExecStart=/usr/bin/java --enable-native-access=ALL-UNNAMED -jar -Xmx2g reitti.jar
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/photon.service
[Unit]
Description=Photon Geocoding Service (Germany, OpenSearch)
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/photon
ExecStart=/usr/bin/java -Xmx4g -jar photon.jar \
  -data-dir /opt/photon \
  -listen-port 2322 \
  -listen-ip 0.0.0.0 \
  -cors-any
Restart=on-failure
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now photon
systemctl enable -q --now reitti
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
