#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docmost.com/

APP="Docmost"
var_tags="documents"
var_cpu="3"
var_ram="3072"
var_disk="7"
var_os="debian"
var_version="12"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/docmost ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/docmost/docmost/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop docmost
    msg_ok "${APP} Stopped"

    msg_info "Updating ${APP} to v${RELEASE}"
    cp /opt/docmost/.env /opt/
    rm -rf /opt/docmost
    temp_file=$(mktemp)
    wget -q "https://github.com/docmost/docmost/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
    tar -xzf "$temp_file"
    mv docmost-${RELEASE} /opt/docmost
    cd /opt/docmost
    mv /opt/.env /opt/docmost/.env
    pnpm install --force &>/dev/null
    pnpm build &>/dev/null
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start docmost
    msg_ok "Started ${APP}"

    msg_info "Cleaning Up"
    rm -f ${temp_file}
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
