#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FuzzyGrim/Yamtrack

APP="Yamtrack"
var_tags="${var_tags:-media;tracker;movies;anime}"
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

  if [[ ! -d /opt/yamtrack ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "yamtrack" "FuzzyGrim/Yamtrack"; then
    msg_info "Stopping Services"
    systemctl stop yamtrack yamtrack-celery
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/yamtrack/src/.env /opt/yamtrack_env.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "yamtrack" "FuzzyGrim/Yamtrack" "tarball"

    msg_info "Installing Python Dependencies"
    cd /opt/yamtrack
    $STD uv venv --clear .venv
    $STD uv pip install --no-cache-dir -r requirements.txt
    msg_ok "Installed Python Dependencies"

    msg_info "Restoring Data"
    cp /opt/yamtrack_env.bak /opt/yamtrack/src/.env
    rm -f /opt/yamtrack_env.bak
    msg_ok "Restored Data"

    msg_info "Updating Yamtrack"
    cd /opt/yamtrack/src
    $STD /opt/yamtrack/.venv/bin/python manage.py migrate
    $STD /opt/yamtrack/.venv/bin/python manage.py collectstatic --noinput
    msg_ok "Updated Yamtrack"

    msg_info "Updating Nginx Configuration"
    cp /opt/yamtrack/nginx.conf /etc/nginx/nginx.conf
    sed -i 's|user abc;|user www-data;|' /etc/nginx/nginx.conf
    sed -i 's|pid /tmp/nginx.pid;|pid /run/nginx.pid;|' /etc/nginx/nginx.conf
    sed -i 's|/yamtrack/staticfiles/|/opt/yamtrack/src/staticfiles/|' /etc/nginx/nginx.conf
    sed -i 's|error_log /dev/stderr|error_log /var/log/nginx/error.log|' /etc/nginx/nginx.conf
    sed -i 's|access_log /dev/stdout|access_log /var/log/nginx/access.log|' /etc/nginx/nginx.conf
    $STD systemctl reload nginx
    msg_ok "Updated Nginx Configuration"

    msg_info "Starting Services"
    systemctl start yamtrack yamtrack-celery
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
