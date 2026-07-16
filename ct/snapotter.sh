#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://snapotter.com

APP="SnapOtter"
var_tags="${var_tags:-media;image}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_arm64="${var_arm64:-no}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/snapotter ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NEEDS_V2_MIGRATION=false
  grep -q '^DB_PATH=' /opt/snapotter_data/.env 2>/dev/null && NEEDS_V2_MIGRATION=true
  UPDATE_AVAILABLE=false
  check_for_gh_release "snapotter" "snapotter-hq/SnapOtter" && UPDATE_AVAILABLE=true

  if [[ "$NEEDS_V2_MIGRATION" == true || "$UPDATE_AVAILABLE" == true ]]; then
    msg_info "Stopping Service"
    systemctl stop snapotter
    msg_ok "Stopped Service"

    PG_VERSION="17" setup_postgresql

    msg_info "Waiting for PostgreSQL"
    PG_READY=0
    for _ in {1..30}; do
      if pg_isready -q -h 127.0.0.1 -p 5432; then
        PG_READY=1
        break
      fi
      sleep 1
    done
    if [[ "$PG_READY" -ne 1 ]]; then
      msg_error "PostgreSQL is not accepting connections on 127.0.0.1:5432 after 30s"
      exit 1
    fi
    msg_ok "PostgreSQL is ready"

    if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = 'snapotter'" | grep -qx '1'; then
      PG_DB_NAME="snapotter" PG_DB_USER="snapotter" setup_postgresql_db
    else
      PG_DB_NAME="snapotter"
      PG_DB_USER="snapotter"
      PG_DB_PASS=$(sed -n 's|^DATABASE_URL=postgres://snapotter:\([^@]*\)@.*|\1|p' /opt/snapotter_data/.env | head -n1)
      if [[ -z "$PG_DB_PASS" ]]; then
        msg_error "SnapOtter's PostgreSQL database exists, but its password is not available in /opt/snapotter_data/.env"
        exit 1
      fi
    fi

    msg_info "Installing Redis"
    $STD apt install -y redis-server
    if grep -q '^appendonly ' /etc/redis/redis.conf; then
      sed -i 's/^appendonly .*/appendonly yes/' /etc/redis/redis.conf
    else
      echo 'appendonly yes' >>/etc/redis/redis.conf
    fi
    $STD systemctl enable --now redis-server
    msg_ok "Installed Redis"

    msg_info "Migrating SnapOtter Configuration"
    sed -i '/^DB_PATH=/d; /^DATABASE_URL=/d; /^REDIS_URL=/d; /^SQLITE_MIGRATE_PATH=/d' /opt/snapotter_data/.env
    cat <<EOF >>/opt/snapotter_data/.env
DATABASE_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
REDIS_URL=redis://127.0.0.1:6379
EOF
    if [[ -f /opt/snapotter_data/snapotter.db ]]; then
      echo 'SQLITE_MIGRATE_PATH=/opt/snapotter_data/snapotter.db' >>/opt/snapotter_data/.env
    fi
    if ! grep -q '^Requires=postgresql.service redis-server.service$' /etc/systemd/system/snapotter.service; then
      sed -i '/^After=/c\After=network-online.target postgresql.service redis-server.service' /etc/systemd/system/snapotter.service
      sed -i '/^\[Unit\]/a Wants=network-online.target\nRequires=postgresql.service redis-server.service' /etc/systemd/system/snapotter.service
    fi
    systemctl daemon-reload
    msg_ok "Migrated SnapOtter Configuration"

    if [[ "$UPDATE_AVAILABLE" == true ]]; then
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "snapotter" "snapotter-hq/SnapOtter" "prebuild" "latest" "/opt/snapotter" "snapotter-*-linux-amd64.tar.gz"
    fi

    msg_info "Updating SnapOtter"
    $STD uv python install 3.11
    $STD uv venv --seed --python 3.11 /opt/snapotter_data/ai/venv
    ln -sfn /opt/snapotter /app
    msg_ok "Updated SnapOtter"

    msg_info "Starting Service"
    systemctl start snapotter
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
echo -e "${GATEWAY}${BGN}http://${IP}:1349${CL}"
