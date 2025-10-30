#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: ekke85 | MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dispatcharr/Dispatcharr

APP="Dispatcharr"
var_tags="${var_tags:-media;arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d "/opt/dispatcharr" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  setup_uv
  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "Dispatcharr" "Dispatcharr/Dispatcharr"; then
    msg_info "Stopping Services"
    systemctl stop dispatcharr-celery
    systemctl stop dispatcharr-celerybeat
    systemctl stop dispatcharr-daphne
    systemctl stop dispatcharr
    msg_ok "Stopped Services"

    msg_info "Creating Backup"
    BACKUP_FILE="/opt/dispatcharr_backup_$(date +%F_%H-%M-%S).tar.gz"
    if [[ -f /opt/dispatcharr/.env ]]; then
      cp /opt/dispatcharr/.env /tmp/dispatcharr.env.backup
    fi
    if [[ -f /opt/dispatcharr/start-gunicorn.sh ]]; then
      cp /opt/dispatcharr/start-gunicorn.sh /tmp/start-gunicorn.sh.backup
    fi
    if [[ -f /opt/dispatcharr/start-celery.sh ]]; then
      cp /opt/dispatcharr/start-celery.sh /tmp/start-celery.sh.backup
    fi
    if [[ -f /opt/dispatcharr/start-celerybeat.sh ]]; then
      cp /opt/dispatcharr/start-celerybeat.sh /tmp/start-celerybeat.sh.backup
    fi
    if [[ -f /opt/dispatcharr/start-daphne.sh ]]; then
      cp /opt/dispatcharr/start-daphne.sh /tmp/start-daphne.sh.backup
    fi
    if [[ -f /opt/dispatcharr/.env ]]; then
      set -o allexport
      source /opt/dispatcharr/.env
      set +o allexport
      if [[ -n "$POSTGRES_DB" ]] && [[ -n "$POSTGRES_USER" ]] && [[ -n "$POSTGRES_PASSWORD" ]]; then
        PGPASSWORD=$POSTGRES_PASSWORD pg_dump -U $POSTGRES_USER -h ${POSTGRES_HOST:-localhost} $POSTGRES_DB >/tmp/dispatcharr_db_$(date +%F).sql
        msg_info "Database backup created"
      fi
    fi
    $STD tar -czf "$BACKUP_FILE" -C /opt dispatcharr /tmp/dispatcharr_db_*.sql
    msg_ok "Backup created: $BACKUP_FILE"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "dispatcharr" "Dispatcharr/Dispatcharr"

    msg_info "Updating Dispatcharr Backend"
    if [[ -f /tmp/dispatcharr.env.backup ]]; then
      mv /tmp/dispatcharr.env.backup /opt/dispatcharr/.env
    fi
    if [[ -f /tmp/start-gunicorn.sh.backup ]]; then
      mv /tmp/start-gunicorn.sh.backup /opt/dispatcharr/start-gunicorn.sh
    fi
    if [[ -f /tmp/start-celery.sh.backup ]]; then
      mv /tmp/start-celery.sh.backup /opt/dispatcharr/start-celery.sh
    fi
    if [[ -f /tmp/start-celerybeat.sh.backup ]]; then
      mv /tmp/start-celerybeat.sh.backup /opt/dispatcharr/start-celerybeat.sh
    fi
    if [[ -f /tmp/start-daphne.sh.backup ]]; then
      mv /tmp/start-daphne.sh.backup /opt/dispatcharr/start-daphne.sh
    fi

    cd /opt/dispatcharr
    rm -rf .venv
    $STD uv venv
    $STD uv pip install -r requirements.txt --index-strategy unsafe-best-match
    $STD uv pip install gunicorn gevent celery redis daphne
    msg_ok "Updated Dispatcharr Backend"

    msg_info "Building Frontend"
    cd /opt/dispatcharr/frontend
    $STD npm install --legacy-peer-deps
    $STD npm run build
    msg_ok "Built Frontend"

    msg_info "Running Django Migrations"
    cd /opt/dispatcharr
    if [[ -f .env ]]; then
      set -o allexport
      source .env
      set +o allexport
    fi
    $STD uv run python manage.py migrate --noinput
    $STD uv run python manage.py collectstatic --noinput
    msg_ok "Migrations Complete"

    msg_info "Starting Services"
    systemctl start dispatcharr
    systemctl start dispatcharr-celery
    systemctl start dispatcharr-celerybeat
    systemctl start dispatcharr-daphne
    msg_ok "Started Services"

    msg_info "Cleaning up"
    rm -f /tmp/dispatcharr_db_*.sql
    msg_ok "Cleanup completed"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
