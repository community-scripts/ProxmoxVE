#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/babybuddy/babybuddy

APP="Baby Buddy"
var_tags="${var_tags:-baby}"
var_disk="${var_disk:-5}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/babybuddy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "babybuddy" "babybuddy/babybuddy"; then
    setup_uv

    msg_info "Stopping Services"
    systemctl stop nginx
    systemctl stop uwsgi
    msg_ok "Services Stopped"

    msg_info "Cleaning old files"
    cp /opt/babybuddy/babybuddy/settings/production.py /tmp/production.py.bak
    find . -mindepth 1 -maxdepth 1 ! -name '.venv' -exec rm -rf {} +
    msg_ok "Cleaned old files"

    fetch_and_deploy_gh_release "babybuddy" "babybuddy/babybuddy"

    msg_info "Updating ${APP}"
    cd /opt/babybuddy
    mv /tmp/production.py.bak /opt/babybuddy/babybuddy/settings/production.py
    source .venv/bin/activate
    $STD uv pip install -r requirements.txt
    $STD python manage.py migrate
    msg_ok "Updated ${APP}"

    msg_info "Fixing permissions"
    chown -R www-data:www-data /opt/data
    chmod 640 /opt/data/db.sqlite3
    chmod 750 /opt/data
    msg_ok "Permissions fixed"

    msg_info "Starting Services"
    systemctl start uwsgi
    systemctl start nginx
    msg_ok "Services Started"
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
