#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sabnzbd.org/

APP="SABnzbd"
var_tags="${var_tags:-downloader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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

    if [[ ! -d /opt/sabnzbd ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    setup_uv
    RELEASE=$(curl -fsSL https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ -f /opt/${APP}_version.txt ]] && [[ "${RELEASE}" == "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_ok "No update required. ${APP} is already at ${RELEASE}"
        exit
    fi
    setup_uv
    msg_info "Updating $APP to ${RELEASE}"
    systemctl stop sabnzbd
    cp -r /opt/sabnzbd /opt/sabnzbd_backup_$(date +%s)
    temp_file=$(mktemp)
    curl -fsSL "https://github.com/sabnzbd/sabnzbd/releases/download/${RELEASE}/SABnzbd-${RELEASE}-src.tar.gz" -o "$temp_file"
    tar -xzf "$temp_file" -C /opt/sabnzbd --strip-components=1
    rm -f "$temp_file"
    if [[ ! -d /opt/sabnzbd/venv ]]; then
        msg_info "Migrating SABnzbd to uv virtual environment"
        $STD uv venv /opt/sabnzbd/venv
        msg_ok "Created uv venv at /opt/sabnzbd/venv"

        if grep -q "ExecStart=python3 SABnzbd.py" /etc/systemd/system/sabnzbd.service; then
            sed -i "s|ExecStart=python3 SABnzbd.py|ExecStart=/opt/sabnzbd/venv/bin/python SABnzbd.py|" /etc/systemd/system/sabnzbd.service
            systemctl daemon-reload
            msg_ok "Updated SABnzbd service to use uv venv"
        fi
    fi
    $STD uv pip install --upgrade pip --python=/opt/sabnzbd/venv/bin/python
    $STD uv pip install -r /opt/sabnzbd/requirements.txt --python=/opt/sabnzbd/venv/bin/python
    echo "${RELEASE}" >/opt/${APP}_version.txt
    systemctl start sabnzbd
    msg_ok "Updated ${APP} to ${RELEASE}"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7777${CL}"
