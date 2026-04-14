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
  libpq-dev \
  zstd \
  nginx
msg_ok "Installed Dependencies"

JAVA_VERSION="25" setup_java
PG_VERSION="17" PG_MODULES="postgis" setup_postgresql
PG_DB_NAME="reitti_db" PG_DB_USER="reitti" PG_DB_EXTENSIONS="postgis" setup_postgresql_db

USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "reitti" "dedicatedcode/reitti" "singlefile" "latest" "/opt/reitti" "reitti-app.jar"
mv /opt/reitti/reitti-*.jar /opt/reitti/reitti.jar

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
msg_ok "Installed Nginx Tile Cache"

msg_info "Creating Reitti Configuration-File"
mkdir -p /opt/reitti/data
cat <<EOF >/opt/reitti/application.properties
# Server configuration
server.port=8080
server.servlet.context-path=/
server.forward-headers-strategy=framework
server.compression.enabled=true
server.compression.min-response-size=1024
server.compression.mime-types=text/plain,application/json

# Logging configuration
logging.level.root=INFO
logging.level.org.hibernate.engine.jdbc.spi.SqlExceptionHelper=FATAL
logging.level.com.dedicatedcode.reitti=INFO

# Internationalization
spring.messages.basename=messages
spring.messages.encoding=UTF-8
spring.messages.cache-duration=3600
spring.messages.fallback-to-system-locale=false

# PostgreSQL configuration
spring.datasource.url=jdbc:postgresql://127.0.0.1:5432/$PG_DB_NAME
spring.datasource.username=$PG_DB_USER
spring.datasource.password=$PG_DB_PASS
spring.datasource.hikari.maximum-pool-size=20

# Redis configuration
spring.data.redis.host=127.0.0.1
spring.data.redis.port=6379
spring.data.redis.username=
spring.data.redis.password=
spring.data.redis.database=0
spring.cache.redis.key-prefix=

spring.cache.cache-names=processed-visits,significant-places,users,magic-links,configurations,transport-mode-configs,avatarThumbnails,avatarData,user-settings
spring.cache.redis.time-to-live=1d

# Upload configuration
spring.servlet.multipart.max-file-size=5GB
spring.servlet.multipart.max-request-size=5GB
server.tomcat.max-part-count=100

# Rqueue configuration
rqueue.web.enable=false
rqueue.job.enabled=false
rqueue.message.durability.in-terminal-state=0
rqueue.key.prefix=\${spring.cache.redis.key-prefix}
rqueue.message.converter.provider.class=com.dedicatedcode.reitti.config.RQueueCustomMessageConverter

# Application-specific settings
reitti.server.advertise-uri=

reitti.security.local-login.disable=false

# OIDC / Security Settings
reitti.security.oidc.enabled=false
reitti.security.oidc.registration.enabled=false

reitti.import.batch-size=10000
reitti.import.processing-idle-start-time=10

reitti.geo-point-filter.max-speed-kmh=1000
reitti.geo-point-filter.max-accuracy-meters=100
reitti.geo-point-filter.history-lookback-hours=24
reitti.geo-point-filter.window-size=50

reitti.process-data.schedule=0 */10 * * * *
reitti.process-data.refresh-views.schedule=0 0 4 * * *
reitti.imports.schedule=0 5/10 * * * *
reitti.imports.owntracks-recorder.schedule=\${reitti.imports.schedule}

# Geocoding service configuration
reitti.geocoding.max-errors=10
reitti.geocoding.photon.base-url=

# Tiles Configuration
reitti.ui.tiles.cache.url=http://127.0.0.1
reitti.ui.tiles.default.service=https://tile.openstreetmap.org/{z}/{x}/{y}.png
reitti.ui.tiles.default.attribution=&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors

# Data management configuration
reitti.data-management.enabled=false
reitti.data-management.preview-cleanup.cron=0 0 4 * * *

reitti.storage.path=data/
reitti.storage.cleanup.cron=0 0 4 * * *

# Location data density normalization
reitti.location.density.target-points-per-minute=4

# Logging buffer
reitti.logging.buffer-size=1000
reitti.logging.max-buffer-size=10000

spring.config.import=optional:oidc.properties
EOF
msg_ok "Created Configuration-File for Reitti"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/reitti.service
[Unit]
Description=Reitti
After=network.target postgresql.service redis-server.service
Wants=postgresql.service redis-server.service

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

systemctl enable -q --now reitti
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
