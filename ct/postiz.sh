#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gitroomhq/postiz-app

APP="Postiz"
var_tags="${var_tags:-social-media;scheduling;automation}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
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

    if [[ ! -d /opt/postiz ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if check_for_gh_release "postiz" "gitroomhq/postiz-app"; then
        msg_info "Stopping Services"
        systemctl stop postiz-orchestrator postiz-frontend postiz-backend
        msg_ok "Stopped Services"

        create_backup /opt/postiz/.env \
            /opt/postiz/uploads

        CLEAN_INSTALL=1 fetch_and_deploy_gh_release "postiz" "gitroomhq/postiz-app" "tarball"

        msg_info "Building Application"
        cd /opt/postiz
        cp /opt/postiz_env.bak /opt/postiz/.env
        set -a && source /opt/postiz/.env && set +a
        export NODE_OPTIONS="--max-old-space-size=4096"
        $STD pnpm install
        $STD pnpm run build
        unset NODE_OPTIONS
        msg_ok "Built Application"

        msg_info "Running Database Migrations"
        cd /opt/postiz
        $STD pnpm run prisma-db-push
        msg_ok "Ran Database Migrations"

        mkdir -p /opt/postiz/uploads
        restore_backup

        msg_info "Starting Services"
        systemctl start postiz-backend postiz-frontend postiz-orchestrator
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
