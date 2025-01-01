#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tandoor.dev/

# App Default Values
APP="Tandoor"
var_tags="recipes"
var_cpu="4"
var_ram="4096"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/tandoor ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if cd /opt/tandoor && git pull | grep -q 'Already up to date'; then
    msg_ok "There is currently no update available."
  else
    msg_info "Updating ${APP} (Patience)"
    export $(cat /opt/tandoor/.env | grep "^[^#]" | xargs)
    cd /opt/tandoor/
    pip3 install -r requirements.txt >/dev/null 2>&1
    /usr/bin/python3 /opt/tandoor/manage.py migrate >/dev/null 2>&1
    /usr/bin/python3 /opt/tandoor/manage.py collectstatic --no-input >/dev/null 2>&1
    /usr/bin/python3 /opt/tandoor/manage.py collectstatic_js_reverse >/dev/null 2>&1
    cd /opt/tandoor/vue
    yarn install >/dev/null 2>&1
    yarn build >/dev/null 2>&1
    systemctl restart gunicorn_tandoor
    msg_ok "Updated ${APP}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8002${CL}"