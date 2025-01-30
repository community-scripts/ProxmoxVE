#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zabbix.com/

# App Default Values
APP="Zabbix"
var_tags="monitoring"
var_cpu="2"
var_ram="4096"
var_disk="6"
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
    if [[ ! -f /etc/zabbix/zabbix_server.conf ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP} Services"
    systemctl stop zabbix-server zabbix-agent2
    msg_ok "Stopped ${APP} Services"

    msg_info "Updating $APP LXC"
    mkdir -p /opt/zabbix-backup/
    cp /etc/zabbix/zabbix_server.conf /opt/zabbix-backup/
    cp /etc/apache2/conf-enabled/zabbix.conf /opt/zabbix-backup/
    cp -R /usr/share/zabbix/ /opt/zabbix-backup/
    #cp -R /usr/share/zabbix-* /opt/zabbix-backup/ Remove temporary
    rm -Rf /etc/apt/sources.list.d/zabbix.list
    cd /tmp
    wget -q https://repo.zabbix.com/zabbix/7.2/release/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian12_all.deb
    dpkg -i zabbix-release_latest+debian12_all.deb &>/dev/null
    apt-get update &>/dev/null
    apt-get install --only-upgrade zabbix-server-pgsql zabbix-frontend-php zabbix-agent2 zabbix-agent2-plugin-* &>/dev/null

    msg_info "Starting ${APP} Services"
    systemctl start zabbix-server zabbix-agent2
    systemctl restart apache2
    msg_ok "Started ${APP} Services"

    msg_info "Cleaning Up"
    rm -rf /tmp/zabbix-release_latest+debian12_all.deb
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/zabbix${CL}"
