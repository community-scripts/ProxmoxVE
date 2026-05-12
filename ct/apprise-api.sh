#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: SystemIdleProcess
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/caronc/apprise-api

APP="Apprise-API"
var_tags="${var_tags:-notification}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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

  if [[ ! -d "/opt/apprise" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "apprise" "caronc/apprise-api"; then
    msg_info "Stopping Service"
    systemctl stop apprise-api
    msg_ok "Stopped Service"

    PYTHON_VERSION="3.12" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "apprise" "caronc/apprise-api" "tarball"

    msg_info "Updating Apprise-API"
    cd /opt/apprise
    cp ./requirements.txt /etc/requirements.txt
    $STD apt install -y nginx git
    $STD uv pip install -r requirements.txt gunicorn supervisor --system
    cp -fr apprise_api/static /usr/share/nginx/html/s/
    mv apprise_api/ webapp
    touch /etc/nginx/server-override.conf
    touch /etc/nginx/location-override.conf
    mkdir -p /config/store /attach /plugin /tmp/apprise /opt/apprise/logs
    chmod 1777 /tmp/apprise && chmod 777 /config /config/store /attach /plugin /opt/apprise/logs
    sed -i \
      -e '/[[]program:nginx]/,/^[[]/ s|stdout_logfile=/dev/stdout|stdout_logfile=/opt/apprise/logs/nginx.log|' \
      -e '/[[]program:nginx]/,/^[[]/ s|stderr_logfile=/dev/stderr|stderr_logfile=/opt/apprise/logs/nginx_error.log|' \
      -e '/[[]program:gunicorn]/,/^[[]/ s|stdout_logfile=/dev/stdout|stdout_logfile=/opt/apprise/logs/gunicorn.log|' \
      -e '/[[]program:gunicorn]/,/^[[]/ s|stderr_logfile=/dev/stderr|stderr_logfile=/opt/apprise/logs/gunicorn_error.log|' \
      -e '/[[]supervisord]/,/^[[]/ s|logfile=/dev/null|logfile=/opt/apprise/logs/supervisor.log|' \
      -e 's|_maxbytes=0|_maxbytes=10485760|g' \
      /opt/apprise/webapp/etc/supervisord.conf
    msg_ok "Updated Apprise-API"

    msg_info "Starting Service"
    systemctl start apprise-api
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
