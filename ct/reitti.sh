#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dedicatedcode/reitti

APP="Reitti"
var_tags="${var_tags:-location-tracker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /opt/reitti/reitti.jar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Enable PostGIS extension if not already enabled
  if systemctl is-active --quiet postgresql; then
    if ! sudo -u postgres psql -d reitti_db -tAc "SELECT 1 FROM pg_extension WHERE extname='postgis'" 2>/dev/null | grep -q 1; then
      msg_info "Enabling PostGIS extension"
      sudo -u postgres psql -d reitti_db -c "CREATE EXTENSION IF NOT EXISTS postgis;" &>/dev/null
      msg_ok "Enabled PostGIS extension"
    fi
  fi

  # Migrate v3 -> v4: Remove RabbitMQ (no longer required) / Photon / Spring Settings
  if systemctl is-enabled --quiet rabbitmq-server 2>/dev/null; then
    msg_info "Migrating to v4: Removing RabbitMQ"
    systemctl stop rabbitmq-server
    systemctl disable rabbitmq-server
    $STD apt-get purge -y rabbitmq-server erlang-base
    $STD apt-get autoremove -y
    msg_ok "Removed RabbitMQ"
  fi

  if systemctl is-enabled --quiet photon 2>/dev/null; then
    msg_info "Migrating to v4: Removing Photon service"
    systemctl stop photon
    systemctl disable photon
    rm -f /etc/systemd/system/photon.service
    systemctl daemon-reload
    msg_ok "Removed Photon service"
  fi

  if grep -q "spring.rabbitmq\|PHOTON_BASE_URL\|PROCESSING_WAIT_TIME\|DANGEROUS_LIFE" /opt/reitti/application.properties 2>/dev/null; then
    msg_info "Migrating to v4: Rewriting application.properties"
    local DB_URL DB_USER DB_PASS
    DB_URL=$(grep '^spring.datasource.url=' /opt/reitti/application.properties | cut -d'=' -f2-)
    DB_USER=$(grep '^spring.datasource.username=' /opt/reitti/application.properties | cut -d'=' -f2-)
    DB_PASS=$(grep '^spring.datasource.password=' /opt/reitti/application.properties | cut -d'=' -f2-)
    cp /opt/reitti/application.properties /opt/reitti/application.properties.bak
    cat <<PROPEOF >/opt/reitti/application.properties
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
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASS}
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
PROPEOF
    # Update reitti.service dependencies
    if [[ -f /etc/systemd/system/reitti.service ]]; then
      sed -i 's/ rabbitmq-server\.service//g; s/ photon\.service//g' /etc/systemd/system/reitti.service
      systemctl daemon-reload
    fi
    msg_ok "Rewrote application.properties (backup: application.properties.bak)"
  fi

  # Migrate v4 -> v5: Remove Rqueue configuration (replaced by Quartz Scheduler)
  if grep -q "^rqueue\." /opt/reitti/application.properties 2>/dev/null; then
    msg_info "Migrating to v5: Removing Rqueue configuration"
    sed -i '/^# Rqueue configuration$/d; /^rqueue\./d' /opt/reitti/application.properties
    msg_ok "Removed Rqueue configuration"
  fi

  # Migrate v4 -> v5: Update application.properties and nginx tile cache for v5 compatibility
  if grep -q "^reitti\.process-data\.schedule=" /opt/reitti/application.properties 2>/dev/null; then
    msg_info "Migrating to v5: Updating application.properties"
    sed -i '/^reitti\.process-data\.schedule=/d' /opt/reitti/application.properties
    sed -i 's/^reitti\.import\.processing-idle-start-time=.*/reitti.import.grace-time-seconds=30/' /opt/reitti/application.properties
    sed -i 's/^spring\.datasource\.hikari\.maximum-pool-size=20$/spring.datasource.hikari.maximum-pool-size=30/' /opt/reitti/application.properties
    grep -q "devices" /opt/reitti/application.properties || \
      sed -i 's/^spring\.cache\.cache-names=\(.*\)$/spring.cache.cache-names=\1,devices,mapStyles,mapStyleJson/' /opt/reitti/application.properties
    grep -q "org.quartz.core.ErrorLogger" /opt/reitti/application.properties || \
      sed -i '/^logging\.level\.com\.dedicatedcode\.reitti=/a logging.level.org.quartz.core.ErrorLogger=FATAL' /opt/reitti/application.properties
    grep -q "^spring.servlet.multipart.resolve-lazily=" /opt/reitti/application.properties || \
      sed -i '/^spring\.servlet\.multipart\.max-request-size=/a spring.servlet.multipart.resolve-lazily=true' /opt/reitti/application.properties
    grep -q "^spring.mvc.async.request-timeout=" /opt/reitti/application.properties || \
      echo "spring.mvc.async.request-timeout=600000" >>/opt/reitti/application.properties
    if ! grep -q "^spring.quartz" /opt/reitti/application.properties; then
      cat >>/opt/reitti/application.properties <<'QUARTZEOF'

# Quartz Scheduler configuration
spring.quartz.job-store-type=jdbc
spring.quartz.jdbc.initialize-schema=never
spring.quartz.properties.org.quartz.jobStore.driverDelegateClass=org.quartz.impl.jdbcjobstore.PostgreSQLDelegate
spring.quartz.properties.org.quartz.jobStore.isClustered=false
spring.quartz.properties.org.quartz.jobStore.tablePrefix=qrtz_
spring.quartz.properties.org.quartz.threadPool.threadCount=5
QUARTZEOF
    fi
    grep -q "^reitti.import.staging.cleanup.cron=" /opt/reitti/application.properties || \
      echo "reitti.import.staging.cleanup.cron=0 0 4 * * *" >>/opt/reitti/application.properties
    grep -q "^reitti.batching.max-batch-size=" /opt/reitti/application.properties || \
      printf "reitti.batching.max-batch-size=100\nreitti.batching.max-wait-time=5\n" >>/opt/reitti/application.properties
    grep -q "^reitti.jobs.cleanup.cron=" /opt/reitti/application.properties || \
      printf "reitti.jobs.cleanup.cron=0 0 4 * * ?\nreitti.jobs.cleanup.max-age-hours=24\n" >>/opt/reitti/application.properties
    grep -q "^reitti.db-janitor.schedule=" /opt/reitti/application.properties || \
      echo "reitti.db-janitor.schedule=0 0 4 * * ?" >>/opt/reitti/application.properties
    msg_ok "Updated application.properties for v5"

    if [[ -f /etc/nginx/nginx.conf ]]; then
      msg_info "Migrating to v5: Updating nginx tile cache configuration"
      cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.v5
      cat >/etc/nginx/nginx.conf <<'NGINXEOF'
user www-data;

events {
  worker_connections 1024;
}
http {
  resolver 1.1.1.1 8.8.8.8 valid=30s ipv6=off;
  proxy_cache_path /var/cache/nginx/tiles levels=1:2 keys_zone=tiles:10m max_size=1g inactive=30d use_temp_path=off;
  server {
    listen 80;
    location /custom/ {
      set $upstream_url $http_x_reitti_upstream_url;
      proxy_pass $upstream_url;
      proxy_set_header Host $proxy_host;
      proxy_set_header User-Agent "Reitti/1.0";
      proxy_cache tiles;
      proxy_cache_key $upstream_url;
      proxy_cache_valid 200 30d;
      proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
    }
  }
}
NGINXEOF
      systemctl reload nginx
      msg_ok "Updated nginx tile cache configuration"
    fi
  fi

  if check_for_gh_release "reitti" "dedicatedcode/reitti"; then
    msg_info "Stopping Service"
    systemctl stop reitti
    msg_ok "Stopped Service"

    JAVA_VERSION="25" setup_java

    rm -f /opt/reitti/reitti.jar
    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "reitti" "dedicatedcode/reitti" "singlefile" "latest" "/opt/reitti" "reitti-app.jar"
    mv /opt/reitti/reitti-*.jar /opt/reitti/reitti.jar

    msg_warn "v5 runs a one-time database migration on first start (GPS points → device table). This may take several minutes on large datasets — do not interrupt the container."
    msg_info "Starting Service"
    systemctl start reitti
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
    msg_warn "Post-upgrade: Verify each API token has a Device assigned in Settings → API Tokens. Tokens without a device cannot ingest location data in v5."
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
