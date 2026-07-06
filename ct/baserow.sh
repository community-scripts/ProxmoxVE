#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/baserow/baserow

APP="Baserow"
var_tags="${var_tags:-database;nocode;spreadsheet}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-10240}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -d /opt/baserow ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if check_for_gh_release "baserow" "baserow/baserow"; then
        msg_info "Stopping Services"
        systemctl stop baserow-backend baserow-celery baserow-celery-beat baserow-celery-export baserow-frontend
        msg_ok "Stopped Services"

        create_backup /opt/baserow/.env
        CLEAN_INSTALL=1 fetch_and_deploy_gh_release "baserow" "baserow/baserow" "tarball"
        restore_backup

        msg_info "Configuring Baserow"
        cd /opt/baserow/backend
        $STD uv sync --frozen --no-dev
        msg_ok "Configured Baserow"

        msg_info "Rebuilding Frontend"
        cd /opt/baserow/web-frontend
        $STD npm install
        $STD npm run build
        msg_ok "Rebuilt Frontend"

        msg_info "Running Migrations"
        cd /opt/baserow/backend
        set -a && source /opt/baserow/.env && set +a
        export PYTHONPATH="/opt/baserow/backend/src:/opt/baserow/premium/backend/src:/opt/baserow/enterprise/backend/src"
        $STD /opt/baserow/backend/.venv/bin/python src/baserow/manage.py migrate
        msg_ok "Ran Migrations"

        msg_info "Starting Services"
        systemctl start baserow-backend baserow-celery baserow-celery-beat baserow-celery-export baserow-frontend
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
