#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tess1o/geopulse

APP="GeoPulse"
var_tags="${var_tags:-location;tracking;gps}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-12}"
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

  if [[ ! -f /opt/geopulse/backend/geopulse-backend ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "geopulse-backend" "tess1o/geopulse"; then
    msg_info "Backing Up Database"
    mkdir -p /var/lib/geopulse/dumps
    DB_NAME="$(grep -oP '^GEOPULSE_POSTGRES_DB=\K.*' /etc/geopulse/geopulse.env 2>/dev/null)"
    DB_NAME="${DB_NAME:-geopulse}"
    if sudo -u postgres pg_dump -Fc "${DB_NAME}" >"/var/lib/geopulse/dumps/${DB_NAME}-pre-update-$(date +%Y%m%d%H%M%S).dump" 2>/dev/null; then
      msg_ok "Backed Up Database"
    else
      msg_warn "Database backup failed, continuing anyway"
    fi

    msg_info "Stopping Service"
    systemctl stop geopulse-backend
    msg_ok "Stopped Service"

    if [[ "$(uname -m)" == "aarch64" ]]; then
      if grep -qi "raspberry\|bcm" /proc/cpuinfo 2>/dev/null; then
        BINARY_PATTERN="geopulse-backend-native-arm64-compat-*"
      else
        BINARY_PATTERN="geopulse-backend-native-arm64-[!c]*"
      fi
    else
      if grep -q avx2 /proc/cpuinfo && grep -q bmi2 /proc/cpuinfo && grep -q fma /proc/cpuinfo; then
        BINARY_PATTERN="geopulse-backend-native-amd64-[!c]*"
      else
        BINARY_PATTERN="geopulse-backend-native-amd64-compat-*"
      fi
    fi

    fetch_and_deploy_gh_release "geopulse-backend" "tess1o/geopulse" "singlefile" "latest" "/opt/geopulse/backend" "${BINARY_PATTERN}"
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="avatars" fetch_and_deploy_gh_release "geopulse-frontend" "tess1o/geopulse" "prebuild" "latest" "/var/www/geopulse" "geopulse-frontend-*.tar.gz"

    if [[ -f /etc/geopulse/geopulse.env ]] && grep -q "GEOPULSE_JWT_" /etc/geopulse/geopulse.env 2>/dev/null; then
      msg_info "Removing Unused JWT Keys"
      sed -i '/^GEOPULSE_JWT_PRIVATE_KEY_LOCATION=/d;/^GEOPULSE_JWT_PUBLIC_KEY_LOCATION=/d' /etc/geopulse/geopulse.env
      rm -f /opt/geopulse/keys/jwt-private-key.pem /opt/geopulse/keys/jwt-public-key.pem
      msg_ok "Removed Unused JWT Keys"
    fi

    if [[ -f /etc/nginx/sites-available/geopulse.conf ]] && ! grep -q '\.mjs\$' /etc/nginx/sites-available/geopulse.conf; then
      msg_info "Configuring Nginx for .mjs Assets"
      cp /etc/nginx/sites-available/geopulse.conf /etc/nginx/sites-available/geopulse.conf.pre-mjs.bak

      ANCHOR_LINE="$(grep -n '    add_header Cache-Control "public, max-age=31536000";' /etc/nginx/sites-available/geopulse.conf.pre-mjs.bak | head -1 | cut -d: -f1)"

      if [[ -n "$ANCHOR_LINE" ]]; then
        INSERT_LINE=$((ANCHOR_LINE + 1))
        {
          head -n "$INSERT_LINE" /etc/nginx/sites-available/geopulse.conf.pre-mjs.bak
          cat <<'MJSBLOCK'

    location ~* ^/(?!osm/).*\.mjs$ {
        types {
            application/javascript mjs;
        }
        expires 1y;
        add_header Cache-Control "public, max-age=31536000";
    }
MJSBLOCK
          tail -n "+$((INSERT_LINE + 1))" /etc/nginx/sites-available/geopulse.conf.pre-mjs.bak
        } >/etc/nginx/sites-available/geopulse.conf
      fi

      if [[ -n "$ANCHOR_LINE" ]] && grep -q '\.mjs\$' /etc/nginx/sites-available/geopulse.conf && nginx -t >/dev/null 2>&1; then
        systemctl reload nginx
        msg_ok "Configured Nginx for .mjs Assets"
      else
        cp /etc/nginx/sites-available/geopulse.conf.pre-mjs.bak /etc/nginx/sites-available/geopulse.conf
        nginx -t >/dev/null 2>&1 && systemctl reload nginx
        msg_warn "Could not automatically add the .mjs nginx block (customized config?) - add it manually, see the GeoPulse 2.0.0 upgrade notes"
      fi
    fi

    msg_info "Starting Service"
    systemctl start geopulse-backend
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW} To create an admin account, run:${CL}"
echo -e "${TAB}${BGN}/usr/local/bin/create-geopulse-admin${CL}"
