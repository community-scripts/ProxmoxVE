#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://healthchecks.io/

APP="healthchecks"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

WEB_UI_PORT=3000
WEB_UI_PROTOCOL="https"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/healthchecks ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "healthchecks" "healthchecks/healthchecks"; then
    msg_info "Stopping Services"
    systemctl stop healthchecks
    msg_ok "Stopped Services"

    msg_info "Backing up existing installation"
    BACKUP="/opt/healthchecks-backup-$(date +%F-%H%M)"
    cp -a /opt/healthchecks "$BACKUP"
    msg_ok "Backup created at $BACKUP"

    fetch_and_deploy_gh_release "healthchecks" "healthchecks/healthchecks" "tarball"

    cd /opt/healthchecks
    if [[ -d venv ]]; then
      rm -rf venv
    fi
    msg_info "Recreating Python venv"
    $STD python3 -m venv venv
    $STD source venv/bin/activate
    $STD pip install --upgrade pip wheel
    msg_ok "Created venv"

    msg_info "Installing requirements"
    $STD pip install gunicorn -r requirements.txt
    msg_ok "Installed requirements"

    msg_info "Running Django migrations"
    $STD python manage.py migrate --noinput
    $STD python manage.py collectstatic --noinput
    $STD python manage.py compress
    msg_ok "Completed Django migrations and static build"

    msg_info "Starting Services"
    systemctl start healthchecks
    systemctl reload caddy
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
