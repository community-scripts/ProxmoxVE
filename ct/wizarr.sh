#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
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

    fetch_and_deploy_gh_release "wizarr" "wizarrrr/wizarr"

    msg_info "Updating Wizarr"
    cd /opt/wizarr || exit
    $STD /usr/local/bin/uv sync --frozen
    $STD /usr/local/bin/uv run --frozen pybabel compile -d app/translations
    $STD npm --prefix app/static install
    $STD npm --prefix app/static run build:css
    mkdir -p ./.cache
    $STD tar -xf "$BACKUP_FILE" --directory=/
    if grep -q 'workers' /opt/wizarr/start.sh; then
      sed -i 's/--workers 4//' /opt/wizarr/start.sh
    fi
    if ! grep -qE 'FLASK|WORKERS|VERSION' /opt/wizarr/.env; then
      {
        echo "FLASK_ENV=production"
        echo "GUNICORN_WORKERS=4"
        echo "APP_VERSION=$(sed 's/^20/v&/' ~/.wizarr)"
      } >>/opt/wizarr/.env
    else
      sed -i "s/_VERSION=v.*$/_VERSION=v$(cat ~/.wizarr)/" /opt/wizarr/.env
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

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5690${CL}"
