#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://healthchecks.io/

APP="healthchecks"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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

  if [[ ! -d /opt/healthchecks ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/healthchecks/healthchecks/releases/latest | jq '.tag_name' | sed 's/^"v//;s/"$//')
  if [[ "${RELEASE}" != "$(cat ~/.healthchecks 2>/dev/null)" ]] || [[ ! -f ~/.healthchecks ]]; then
    msg_info "Stopping $APP"
    systemctl stop healthchecks
    msg_ok "Stopped $APP"

    setup_uv
    fetch_and_deploy_gh_release "healthchecks" "healthchecks/healthchecks"

    msg_info "Updating $APP to v${RELEASE}"
    cd /opt/healthchecks
    mkdir -p /opt/healthchecks/static-collected/
    $STD uv pip install wheel gunicorn -r requirements.txt --system
    $STD uv run -- python manage.py makemigrations
    $STD uv run -- python manage.py migrate --noinput
    $STD uv run -- python manage.py collectstatic --noinput
    $STD uv run -- python manage.py compress
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting $APP"
    systemctl start healthchecks
    systemctl restart caddy
    msg_ok "Started $APP"

    msg_ok "Update Successful"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
