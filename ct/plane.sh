#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: onionrings29
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://plane.so | GitHub: https://github.com/makeplane/plane

APP="Plane"
var_tags="${var_tags:-project-management}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/plane ]]; then
    msg_error "No Plane Installation Found!"
    exit 1
  fi

  if check_for_gh_release "plane" "makeplane/plane"; then
    msg_info "Stopping Services"
    systemctl stop plane-api plane-worker plane-beat plane-live plane-space
    msg_ok "Stopped Services"

    create_backup /opt/plane/.env \
        /opt/plane/apps/admin/.env \
        /opt/plane/apps/api/.env \
        /opt/plane/apps/space/.env \
       /opt/plane/apps/web/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "plane" "makeplane/plane" "tarball"

    restore_backup

    msg_info "Rebuilding Frontend (Patience)"
    cd /opt/plane
    export NODE_OPTIONS="--max-old-space-size=4096"
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    $STD corepack enable pnpm
    $STD pnpm install --frozen-lockfile
    $STD pnpm turbo run build --filter=web --filter=admin --filter=space --filter=live
    msg_ok "Rebuilt Frontend"

    msg_info "Updating Python Dependencies"
    cd /opt/plane/apps/api
    export VIRTUAL_ENV=/opt/plane-venv
    $STD uv pip install --upgrade -r requirements/production.txt
    msg_ok "Updated Python Dependencies"

    msg_info "Running Migrations"
    cd /opt/plane/apps/api
    set -a
    source /opt/plane/apps/api/.env
    set +a
    $STD /opt/plane-venv/bin/python manage.py migrate
    $STD /opt/plane-venv/bin/python manage.py collectstatic --noinput
    $STD /opt/plane-venv/bin/python manage.py configure_instance
    msg_ok "Ran Migrations"

    msg_info "Starting Services"
    systemctl start plane-api plane-worker plane-beat plane-live plane-space
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
