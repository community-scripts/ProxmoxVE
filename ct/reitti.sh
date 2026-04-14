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
PROPEOF
    # Update reitti.service dependencies
    if [[ -f /etc/systemd/system/reitti.service ]]; then
      sed -i 's/ rabbitmq-server\.service//g; s/ photon\.service//g' /etc/systemd/system/reitti.service
      systemctl daemon-reload
    fi
    msg_ok "Rewrote application.properties (backup: application.properties.bak)"
  fi

  if check_for_gh_release "reitti" "dedicatedcode/reitti"; then
    msg_info "Stopping Service"
    systemctl stop reitti
    msg_ok "Stopped Service"

    JAVA_VERSION="25" setup_java

    rm -f /opt/reitti/reitti.jar
    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "reitti" "dedicatedcode/reitti" "singlefile" "latest" "/opt/reitti" "reitti-app.jar"
    mv /opt/reitti/reitti-*.jar /opt/reitti/reitti.jar

    msg_info "Starting Service"
    systemctl start reitti
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
