#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wizarrrr/wizarr

APP="Wizarr"
var_tags="${var_tags:-media;arr}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/wizarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  setup_uv

  if check_for_gh_release "wizarr" "wizarrrr/wizarr"; then
    msg_info "Stopping Service"
    systemctl stop wizarr
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    BACKUP_FILE="/opt/wizarr_backup_$(date +%F).tar.gz"
    $STD tar -czf "$BACKUP_FILE" /opt/wizarr/{.env,start.sh} /opt/wizarr/database/ &>/dev/null
    rm -rf /opt/wizarr/migrations/versions/*
    msg_ok "Backup Created"

    fetch_and_deploy_gh_release "wizarr" "wizarrrr/wizarr" "tarball"

    msg_info "Updating Wizarr"
    cd /opt/wizarr
    $STD /usr/local/bin/uv sync --frozen
    $STD /usr/local/bin/uv run --frozen pybabel compile -d app/translations
    $STD npm --prefix app/static install
    $STD npm --prefix app/static run build
    mkdir -p ./.cache
    $STD tar -xf "$BACKUP_FILE" --directory=/
    if grep -q 'bind' /opt/wizarr/start.sh; then
      WIZARR_PORT=$(awk -F: '{print $2}' /opt/wizarr/start.sh | awk -F' ' '{print $1}' | tr -d '[:space:]')
    fi
    sed -i -E -e 's/[[:space:]]+/ /g' \
      -e 's/--workers 4//' \
      -e 's/--bind 0.0.0.0:[0-9]+//' /opt/wizarr/start.sh
    KEYS=("FLASK" "WORKERS" "HOST" "PORT")
    for key in "${KEYS[@]}"; do
      if ! grep -q "$key" /opt/wizarr/.env; then
        cat <<EOF >/opt/wizarr/.env
APP_URL=http://${LOCAL_IP}
DISABLE_BUILTIN_AUTH=false
FLASK_ENV=production
GUNICORN_WORKERS=4
HOST=0.0.0.0
PORT=${WIZARR_PORT:-5690}
LOG_LEVEL=info
APP_VERSION=$(cat ~/.wizarr)
EOF
      fi
      continue
    done
    sed -i "s/_VERSION=.*$/_VERSION=$(cat ~/.wizarr)/" /opt/wizarr/.env
    if grep -q 'abnormal' /etc/systemd/system/wizarr.service; then
      sed -i 's/on-abnormal/always \
RestartSec=10 \
KillMode=mixed \
TimeoutStopSec=10/' /etc/systemd/system/wizarr.service
      systemctl daemon-reload
    fi
    rm -rf "$BACKUP_FILE"
    export FLASK_SKIP_SCHEDULER=true
    $STD /usr/local/bin/uv run --frozen flask db upgrade
    msg_ok "Updated Wizarr"

    msg_info "Starting Service"
    systemctl start wizarr
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5690${CL}"
