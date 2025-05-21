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

  RELEASE=$(curl -fsSL https://api.github.com/repos/babybuddy/babybuddy/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/babybuddy_version.txt)" ]]; then
    setup_uv

    msg_info "Stopping Services"
    systemctl stop nginx
    systemctl stop uwsgi
    msg_ok "Services Stopped"

    msg_info "Cleaning old files"
    cp babybuddy/settings/production.py /tmp/production.py.bak
    find . -mindepth 1 -maxdepth 1 ! -name '.venv' -exec rm -rf {} +
    msg_ok "Cleaned old files"

    msg_info "Updating ${APP} to v${RELEASE}"
    temp_file=$(mktemp)
    curl -fsSL "https://github.com/babybuddy/babybuddy/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
    cd /opt/babybuddy
    tar zxf "$temp_file" --strip-components=1 -C /opt/babybuddy
    mv /tmp/production.py.bak babybuddy/settings/production.py
    cd /opt/babybuddy
    source .venv/bin/activate
    $STD uv pip install -r requirements.txt
    $STD python manage.py migrate
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Fixing permissions"
    chown -R www-data:www-data /opt/data
    chmod 640 /opt/data/db.sqlite3
    chmod 750 /opt/data
    msg_ok "Permissions fixed"

    msg_info "Starting Services"
    systemctl start uwsgi
    systemctl start nginx
    msg_ok "Services Started"

    msg_info "Cleaning up"
    rm -f "$temp_file"
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
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
