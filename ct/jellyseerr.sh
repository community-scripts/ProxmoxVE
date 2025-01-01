#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.jellyseerr.dev/

# App Default Values
APP="Jellyseerr"
var_tags="media"
var_cpu="4"
var_ram="4096"
var_disk="8"
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

    if [[ ! -d /opt/jellyseerr ]]; then 
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if ! command -v pnpm &> /dev/null; then
        msg_error "pnpm not found. Installing..."
        npm install -g pnpm &>/dev/null
    else
        msg_ok "pnpm is already installed."
    fi

    msg_info "Updating $APP"
    cd /opt/jellyseerr
    output=$(git pull --no-rebase)
    
    if echo "$output" | grep -q "Already up to date."; then
        msg_ok "$APP is already up to date."
        exit
    fi

    systemctl stop jellyseerr
    rm -rf dist .next node_modules
    export CYPRESS_INSTALL_BINARY=0
    pnpm install --frozen-lockfile &>/dev/null
    export NODE_OPTIONS="--max-old-space-size=3072"
    pnpm build &>/dev/null

    cat <<EOF >/etc/systemd/system/jellyseerr.service
[Unit]
Description=jellyseerr Service
After=network.target

[Service]
EnvironmentFile=/etc/jellyseerr/jellyseerr.conf
Environment=NODE_ENV=production
Type=exec
WorkingDirectory=/opt/jellyseerr
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start jellyseerr
    msg_ok "Updated $APP"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5055${CL}"