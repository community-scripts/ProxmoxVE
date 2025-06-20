#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: phillarson-xyz
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://garagehq.deuxfleurs.fr/

APP="Garage"
var_tags="${var_tags:-object-storage;s3}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /usr/local/bin/garage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/deuxfleurs-org/garage/releases/latest | grep '"tag_name"' | awk -F '"' '{print $4}')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    rc-service garage stop
    msg_ok "${APP} Stopped"

    msg_info "Updating ${APP} to ${RELEASE}"
    mv /usr/local/bin/garage /usr/local/bin/garage_bak
    GARAGE_VERSION="${RELEASE}"
    ARCH="x86_64-unknown-linux-musl"
    wget -q "https://garagehq.deuxfleurs.fr/_releases/${GARAGE_VERSION}/${ARCH}/garage" -O /usr/local/bin/garage
    chmod +x /usr/local/bin/garage
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    rc-service garage start
    msg_ok "Started ${APP}"

    msg_info "Cleaning up"
    rm -f /usr/local/bin/garage_bak
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
echo -e "${INFO}${YW} Access it using the following URLs:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}S3 API: http://${IP}:3900${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Admin API: http://${IP}:3903${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Web Interface: http://${IP}:3902${CL}"
echo -e "${INFO}${YW} Admin token and setup instructions:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}cat /root/garage-credentials.txt${CL}"