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

  if [ ! -d /var/cache/nginx/tiles ]; then
    msg_info "Installing Nginx Tile Cache"
    mkdir -p /var/cache/nginx/tiles
    $STD apt install -y nginx
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
    echo "reitti.ui.tiles.cache.url=http://127.0.0.1" >> /opt/reitti/application.properties
    systemctl restart reitti
    msg_info "Installed Nginx Tile Cache"
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
  if check_for_gh_release "photon" "komoot/photon"; then
    msg_info "Stopping Service"
    systemctl stop photon
    msg_ok "Stopped Service"

    rm -f /opt/photon/photon.jar
    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "photon" "komoot/photon" "singlefile" "latest" "/opt/photon" "photon-0*.jar"
    mv /opt/photon/photon-*.jar /opt/photon/photon.jar

    msg_info "Starting Service"
    systemctl start photon
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
