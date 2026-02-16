#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (MickLesk)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://linkding.link/

APP="linkding"
var_tags="${var_tags:-bookmarks;management}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -d /opt/linkding ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "linkding" "sissbruecker/linkding"; then
    msg_info "Stopping Services"
    systemctl stop nginx linkding linkding-tasks
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp -r /opt/linkding/data /opt/linkding_data_backup
    cp /opt/linkding/.env /opt/linkding_env_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "linkding" "sissbruecker/linkding"

    msg_info "Restoring Data"
    cp -r /opt/linkding_data_backup/. /opt/linkding/data
    cp /opt/linkding_env_backup /opt/linkding/.env
    rm -rf /opt/linkding_data_backup /opt/linkding_env_backup
    ln -sf /usr/lib/x86_64-linux-gnu/mod_icu.so /opt/linkding/libicu.so
    msg_ok "Restored Data"

    msg_info "Updating LinkDing"
    cd /opt/linkding
    rm -f bookmarks/settings/dev.py
    touch bookmarks/settings/custom.py
    $STD npm ci
    $STD npm run build
    $STD uv sync --no-dev --frozen
    $STD uv pip install gunicorn
    set -a && source /opt/linkding/.env && set +a
    $STD /opt/linkding/.venv/bin/python manage.py migrate
    $STD /opt/linkding/.venv/bin/python manage.py collectstatic --no-input
    msg_ok "Updated LinkDing"

    msg_info "Starting Services"
    systemctl start nginx linkding linkding-tasks
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9090${CL}"
