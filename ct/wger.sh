#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Original Author: Slaviša Arežina (tremor021)
# Revamped Script: Floris Claessens (FlorisCl)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

APP="wger"
var_tags="${var_tags:-management;fitness}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-10}"
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
    
    if [[ ! -d "/opt/wger" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit 1
    fi

    if check_for_gh_release "wger" "wger-project/wger"; then
        msg_info "Stopping services"
        systemctl stop redis-server nginx celery celery-beat wger 2>/dev/null || true
        msg_ok "Services stopped"

        PYTHON_VERSION="3.13" setup_uv
        NODE_VERSION="22" NODE_MODULE="npm,sass" setup_nodejs
        corepack enable

        fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball" "latest"
        
        msg_info "Updating dependencies"
            $STD apt update
            $STD apt -y upgrade
            
            cd /opt/wger

            $STD uv sync --group docker
            $STD uv pip install psycopg2-binary
        msg_ok "Dependencies updated"
        
       msg_info "Running database migrations"
            set -a
            source /opt/wger/wger.env
            set +a
            $STD uv run manage.py migrate --no-input
        msg_ok "Database migrated"
        
        msg_info "Collecting static files"
            $STD uv run python manage.py collectstatic --no-input
        msg_ok "Static files collected"      
        
        if command -v npm &>/dev/null && [[ -f package.json ]]; then
            msg_info "Building frontend assets"
            $STD npm install
            $STD npm run build:css:sass
            msg_ok "Frontend assets built"
        else
            msg_info "Skipping frontend build (npm or package.json not found)"
        fi
        
        msg_info "Starting services"
        systemctl start redis-server wger celery celery-beat nginx
        msg_ok "Services started"
        
    else
        msg_info "No update required. ${APP} is already up-to-date."
    fi
    exit 0
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
