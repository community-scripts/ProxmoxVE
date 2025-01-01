#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://komo.do

# App Default Values
APP="Komodo"
var_tags="docker"
var_cpu="2"
var_ram="2048"
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
    if [[ ! -d /opt/komodo ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating ${APP}"
    COMPOSE_FILE=""
    for file in *.compose.yaml; do
        if [[ "$file" != "compose.env" ]]; then
            COMPOSE_FILE="$file"
            break
        fi
    done

    if [[ -z "$COMPOSE_FILE" ]]; then
        msg_error "No valid compose file found in /opt/komodo!"
        exit 1
    fi

    BACKUP_FILE="${COMPOSE_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
    mv "$COMPOSE_FILE" "$BACKUP_FILE" || {
        msg_error "Failed to create backup of $COMPOSE_FILE!"
        exit 1
    }

    GITHUB_URL="https://raw.githubusercontent.com/mbecker20/komodo/main/compose/$COMPOSE_FILE"
    wget -q -O "$COMPOSE_FILE" "$GITHUB_URL" || {
        msg_error "Failed to download $COMPOSE_FILE from GitHub!"
        mv "$BACKUP_FILE" "$COMPOSE_FILE" 
        exit 1
    }

    docker compose -p komodo -f "/opt/komodo/$COMPOSE_FILE" --env-file /opt/komodo/compose.env up -d &>/dev/null 
    msg_ok "Updated ${APP}"
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9120${CL}"
