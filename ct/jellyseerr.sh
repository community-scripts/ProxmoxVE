#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.jellyseerr.dev/

APP="Jellyseerr"
var_tags="media"
var_cpu="4"
var_ram="4096"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP" 
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

    if [ "$(node -v | cut -c2-3)" -ne 22 ]; then
        msg_info "Updating Node.js Repository"
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
        msg_ok "Updating Node.js Repository"

        msg_info "Updating Packages"
        $STD apt-get update
        $STD apt-get -y upgrade
        msg_ok "Updating Packages"
        
        msg_info "Cleaning up"
        apt-get -y autoremove
        apt-get -y autoclean
        msg_ok "Cleaning up"
    fi

    cd /opt/jellyseerr
    output=$(git pull --no-rebase)

    pnpm_current=$(pnpm --version 2>/dev/null)
    pnpm_desired=$(grep -Po '"pnpm":\s*"\K[^"]+' /opt/jellyseerr/package.json)
    
    if [ -z "$pnpm_current" ]; then
        msg_error "pnpm not found. Installing version $pnpm_desired..."
        $STD npm install -g pnpm@"$pnpm_desired"
    elif ! node -e "const semver = require('semver'); process.exit(semver.satisfies('$pnpm_current', '$pnpm_desired') ? 0 : 1)" ; then
        msg_error "Updating pnpm from version $pnpm_current to $pnpm_desired..."
        $STD npm install -g pnpm@"$pnpm_desired"
    else
        msg_ok "pnpm is already installed and satisfies version $pnpm_desired."
    fi

    msg_info "Updating $APP"
    if echo "$output" | grep -q "Already up to date."; then
        msg_ok "$APP is already up to date."
        exit
    fi

    systemctl stop jellyseerr
    rm -rf dist .next node_modules
    export CYPRESS_INSTALL_BINARY=0
    $STD pnpm install --frozen-lockfile
    export NODE_OPTIONS="--max-old-space-size=3072"
    $STD pnpm build

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
