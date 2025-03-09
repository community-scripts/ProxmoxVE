#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/

APP="Actual Budget"
var_tags="finance"
var_cpu="2"
var_ram="2048"
var_disk="4"
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

    if [[ ! -d /opt/actualbudget ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -s https://api.github.com/repos/actualbudget/actual/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /opt/actualbudget_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/actualbudget_version.txt)" ]]; then
        msg_info "Stopping ${APP}"
        systemctl stop actualbudget
        msg_ok "${APP} Stopped"

        msg_info "Updating ${APP} to ${RELEASE}"
        cd /tmp
        wget -q https://github.com/actualbudget/actual/archive/refs/tags/v${RELEASE}.tar.gz

        mv /opt/actualbudget /opt/actualbudget_bak
        tar -xzf "v${RELEASE}.tar.gz"
        mv actual-${RELEASE} /opt/actualbudget

        mkdir -p /opt/actualbudget-data/{server-files,upload,migrate,user-files,migrations,config}
        for dir in server-files .migrate user-files migrations; do
            if [[ -d /opt/actualbudget_bak/$dir ]]; then
                mv /opt/actualbudget_bak/$dir/* /opt/actualbudget-data/$dir/ || true
            fi
        done
        if [[ -f /opt/actualbudget-data/migrate/.migrations ]]; then
            sed -i 's/null/1732656575219/g' /opt/actualbudget-data/migrate/.migrations
            sed -i 's/null/1732656575220/g' /opt/actualbudget-data/migrate/.migrations
        fi
        if [[ -f /opt/actualbudget/server-files/account.sqlite ]] && [[ ! -f /opt/actualbudget-data/server-files/account.sqlite ]]; then
            mv /opt/actualbudget/server-files/account.sqlite /opt/actualbudget-data/server-files/account.sqlite
        fi

        if [[ -f /opt/actualbudget_bak/selfhost.key ]]; then
            mv /opt/actualbudget_bak/selfhost.key /opt/actualbudget/selfhost.key
            mv /opt/actualbudget_bak/selfhost.crt /opt/actualbudget/selfhost.crt
        fi

        if [[ -f /opt/actualbudget_bak/.env ]]; then
            mv /opt/actualbudget_bak/.env /opt/actualbudget-data/.env
        else
            cat <<EOF >/opt/actualbudget-data/.env
ACTUAL_UPLOAD_DIR=/opt/actualbudget-data/upload
ACTUAL_DATA_DIR=/opt/actualbudget-data
ACTUAL_SERVER_FILES_DIR=/opt/actualbudget-data/server-files
ACTUAL_USER_FILES=/opt/actualbudget-data/user-files
PORT=5006
ACTUAL_TRUSTED_PROXIES="10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,127.0.0.1/32,::1/128,fc00::/7"
ACTUAL_HTTPS_KEY=/opt/actualbudget/selfhost.key
ACTUAL_HTTPS_CERT=/opt/actualbudget/selfhost.crt
EOF
        fi
        cd /opt/actualbudget
        $STD yarn workspaces focus @actual-app/sync-server --production
        echo "${RELEASE}" >/opt/actualbudget_version.txt
        msg_ok "Updated ${APP}"

        msg_info "Starting ${APP}"
        cat <<EOF >/etc/systemd/system/actualbudget.service
[Unit]
Description=Actual Budget Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/actualbudget
EnvironmentFile=/opt/actualbudget-data/.env
ExecStart=/usr/bin/yarn start:server
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl start actualbudget
        msg_ok "Started ${APP}"

        msg_info "Cleaning Up"
        rm -rf /opt/actualbudget_bak
        rm -rf "/tmp/v${RELEASE}.tar.gz"
        msg_ok "Cleaned"
        msg_ok "Updated Successfully"
    else
        msg_ok "No update required. ${APP} is already at ${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:5006${CL}"
