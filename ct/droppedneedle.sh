#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner | Co-Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://droppedneedle.com/ | Github: https://github.com/DroppedNeedle/DroppedNeedle

APP="DroppedNeedle"
var_tags="${var_tags:-arr;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/droppedneedle && ! -d /opt/musicseerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  MIGRATING=false
  [[ -d /opt/musicseerr ]] && MIGRATING=true

  if [[ "$MIGRATING" == "true" ]] || check_for_gh_release "droppedneedle" "DroppedNeedle/DroppedNeedle"; then
    if [[ "$MIGRATING" == "true" ]]; then
      msg_warn "Migrating Musicseerr to DroppedNeedle"
      msg_info "Stopping Musicseerr Service"
      systemctl disable -q --now musicseerr
      msg_ok "Stopped Musicseerr Service"
      DATA_DIR="/opt/musicseerr/backend"
    else
      msg_info "Stopping Service"
      systemctl stop droppedneedle
      msg_ok "Stopped Service"
      DATA_DIR="/opt/droppedneedle/backend"
    fi

    create_backup "$DATA_DIR/config" "$DATA_DIR/cache"

    PYTHON_VERSION="3.13" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "droppedneedle" "DroppedNeedle/DroppedNeedle" "tarball"
    NODE_VERSION="25" NODE_MODULE="pnpm@10.33.0" setup_nodejs

    msg_info "Building Frontend"
    cd /opt/droppedneedle/frontend
    export NODE_OPTIONS="--max-old-space-size=3072"
    rm -rf node_modules build
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    msg_ok "Built Frontend"

    msg_info "Updating Application"
    mkdir -p /opt/droppedneedle/backend/config /opt/droppedneedle/backend/cache
    $STD uv venv --clear /opt/droppedneedle/venv
    $STD uv pip install -r /opt/droppedneedle/backend/requirements.txt --python=/opt/droppedneedle/venv/bin/python
    rm -rf /opt/droppedneedle/backend/static
    cp -r /opt/droppedneedle/frontend/build /opt/droppedneedle/backend/static
    msg_ok "Updated Application"

    restore_backup

    if [[ "$MIGRATING" == "true" ]]; then
      msg_info "Migrating Musicseerr Data"
      rm -rf /opt/droppedneedle/backend/config /opt/droppedneedle/backend/cache
      cp -a /opt/musicseerr/backend/config /opt/droppedneedle/backend/config
      cp -a /opt/musicseerr/backend/cache /opt/droppedneedle/backend/cache
      msg_ok "Migrated Musicseerr Data"

      msg_info "Replacing systemd Service"
      cat <<EOF >/etc/systemd/system/droppedneedle.service
[Unit]
Description=DroppedNeedle Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/droppedneedle/backend
Environment=ROOT_APP_DIR=/opt/droppedneedle/backend
Environment=PORT=8688
# Environment=SLSKD_DOWNLOADS_PATH=<path-to-slskd-downloads>
ExecStart=/opt/droppedneedle/venv/bin/python -m maintenance.automatic_upgrade --start-target
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
      rm -f /etc/systemd/system/musicseerr.service
      msg_ok "Replaced systemd Service"
    else
      if ! grep -q 'SLSKD' /etc/systemd/system/droppedneedle.service; then
        sed -i '\|=8688$|a# Environment=SLSKD_DOWNLOADS_PATH=<path-to-slskd-downloads>' /etc/systemd/system/droppedneedle.service
      fi
      sed -i 's|^ExecStart=.*|ExecStart=/opt/droppedneedle/venv/bin/python -m maintenance.automatic_upgrade --start-target|' /etc/systemd/system/droppedneedle.service
    fi

    systemctl daemon-reload
    if [[ "$MIGRATING" == "true" ]]; then
      msg_info "Enabling DroppedNeedle Service"
      systemctl enable -q --now droppedneedle
      msg_ok "Enabled DroppedNeedle Service"

      sed -i 's/musicseerr/droppedneedle/g' /bin/update
      rm -rf /opt/musicseerr

      msg_info "Waiting up to 1min for backend to boot and retrieve Admin Username"
      for i in {1..30}; do
        username=$(/opt/droppedneedle/venv/bin/python -c 'import sqlite3; conn = sqlite3.connect("/opt/droppedneedle/backend/cache/library.db"); c = conn.cursor(); c.execute("SELECT username FROM auth_users WHERE role=\"admin\""); admin=c.fetchone(); print(admin[0]) if (admin and admin[0]) else None' 2>/dev/null || true)
        if [[ -n "$username" ]]; then
          break
        fi
        sleep 2
      done
      if [[ -n "$username" ]]; then
        msg_ok "Admin Username retrieved (Admin Username is: ${username})"
      else
        msg_warn "Failed to retrieve Admin Username. The backend might still be starting."
      fi
      msg_ok "Migrated successfully!"
    else
      msg_info "Starting Service"
      systemctl start droppedneedle
      msg_ok "Started Service"
      msg_ok "Updated successfully!"
    fi
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8688${CL}"
