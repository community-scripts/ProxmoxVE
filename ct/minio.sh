#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/minio/minio

APP="MinIO"
var_tags="${var_tags:-object-storage}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -f /usr/local/bin/minio ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  FEATURE_RICH_VERSION="2025-04-22T22-12-26Z"
  RELEASE=$(curl -fsSL https://api.github.com/repos/minio/minio/releases/latest | grep '"tag_name"' | awk -F '"' '{print $4}')
  CURRENT_VERSION=""
  [[ -f /opt/${APP}_version.txt ]] && CURRENT_VERSION=$(cat /opt/${APP}_version.txt)
  RELEASE=$(curl -fsSL https://api.github.com/repos/minio/minio/releases/latest | grep '"tag_name"' | awk -F '"' '{print $4}')

  if [[ "${CURRENT_VERSION}" == "${FEATURE_RICH_VERSION}" && "${RELEASE}" != "${FEATURE_RICH_VERSION}" ]]; then
    echo
    echo "You are currently running the last feature-rich community version: ${FEATURE_RICH_VERSION}"
    echo "WARNING: Updating to the latest version will REMOVE most management features from the Console UI."
    echo "Do you still want to upgrade to the latest version? [y/N]: "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      msg_ok "No update performed. Staying on the feature-rich version."
      exit
    fi
  fi

  if [[ "${CURRENT_VERSION}" != "${RELEASE}" ]]; then
    msg_info "Stopping Service"
    systemctl stop minio
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to ${RELEASE}"
    mv /usr/local/bin/minio /usr/local/bin/minio_bak
    curl -fsSL "https://dl.min.io/server/minio/release/linux-amd64/minio" -o /usr/local/bin/minio
    chmod +x /usr/local/bin/minio
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start minio
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -f /usr/local/bin/minio_bak
    msg_ok "Cleaned"

    msg_ok "Updated successfully!"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
