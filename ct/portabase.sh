#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://portabase.io

APP="Portabase"
var_tags="${var_tags:-database;backup}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/portabase ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  TOOLS_CHANGED=false
  if check_for_gh_release "rclone" "rclone/rclone"; then
    TOOLS_CHANGED=true
    fetch_and_deploy_gh_release "rclone" "rclone/rclone" "binary" "latest" "" "rclone-v*-linux-$(arch_resolve).deb"
  fi
  if check_for_gh_release "restic" "restic/restic"; then
    TOOLS_CHANGED=true
    fetch_and_deploy_gh_release "restic" "restic/restic" "singlefile" "latest" "/usr/local/bin" "restic_*_linux_$(arch_resolve).bz2"
  fi
  if ! grep -q "/storage/restic/" /etc/nginx/sites-available/portabase; then
    msg_info "Adding file backup routes to Nginx"
    cat <<'EOF' >/tmp/portabase-storage.conf
    location /storage/restic/ {
        proxy_pass http://127.0.0.1:1081;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /storage/sync/ {
        proxy_pass http://127.0.0.1:1082;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
EOF
    sed -i '/ignore_invalid_headers off;/r /tmp/portabase-storage.conf' /etc/nginx/sites-available/portabase
    rm -f /tmp/portabase-storage.conf
    $STD nginx -t
    systemctl reload nginx
    msg_ok "Added file backup routes to Nginx"
  fi
  if [[ "$TOOLS_CHANGED" == "true" ]]; then
    systemctl restart portabase
  fi

  if check_for_gh_release "portabase" "Portabase/portabase"; then
    msg_info "Stopping Services"
    systemctl stop portabase portabase-tusd
    msg_ok "Stopped Services"

    create_backup /opt/portabase/.env

    NODE_VERSION="22" NODE_MODULE="pnpm@11.8.0" setup_nodejs

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "portabase" "Portabase/portabase" "tarball"

    restore_backup

    msg_info "Building Portabase"
    cd /opt/portabase
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    export NEXT_TELEMETRY_DISABLED=1
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    cp -r /opt/portabase/.next/static /opt/portabase/.next/standalone/.next/static
    cp -r /opt/portabase/public /opt/portabase/.next/standalone/public
    mkdir -p /opt/portabase/.next/standalone/src/db
    cp -r /opt/portabase/src/db/migrations /opt/portabase/.next/standalone/src/db/migrations
    ln -sf /opt/portabase/.env /opt/portabase/.next/standalone/.env
    msg_ok "Built Portabase"

    msg_info "Starting Services"
    systemctl start portabase-tusd portabase
    msg_ok "Started Services"
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
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
