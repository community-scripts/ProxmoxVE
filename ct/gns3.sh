#!/usr/bin/env bash

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Yumgi
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/GNS3/gns3-server

# App Default Values
APP="GNS3"
var_tags="${var_tags:-network;simulation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-22.04}"
var_unprivileged="${var_unprivileged:-0}"  # Privileged required for nesting/Docker

# GNS3 Version Configuration
GNS3_VERSION="${GNS3_VERSION:-latest}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
header_info
check_container_storage
check_container_resources

# Check if installation exists
if [[ ! -f /etc/systemd/system/gns3.service ]]; then
msg_error "No ${APP} Installation Found!"
exit
fi

msg_info "Updating ${APP}"
systemctl stop gns3.service

# Check current version
CURRENT_VERSION=$(gns3server --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
msg_info "Current version: ${CURRENT_VERSION}"

# Update repository
$STD apt-get update

# Unhold package for update
apt-mark unhold gns3-server &>/dev/null

if [[ "$GNS3_VERSION" == "latest" ]]; then
  msg_info "Installing latest GNS3 version"
  $STD apt-get install -y --only-upgrade gns3-server
else
  PACKAGE_VERSION=$(apt-cache madison gns3-server | grep "$GNS3_VERSION" | head -1 | awk '{print $3}')
  if [[ -n "$PACKAGE_VERSION" ]]; then
    msg_info "Installing GNS3 version ${GNS3_VERSION}"
    $STD apt-get install -y gns3-server=${PACKAGE_VERSION}
    $STD apt-mark hold gns3-server
  else
    msg_error "Version ${GNS3_VERSION} not found"
    exit 1
  fi
fi

# Update Docker images
msg_info "Updating Docker images"
docker images --format "{{.Repository}}:{{.Tag}}" | grep gns3 | xargs -r -n 1 docker pull &>/dev/null

systemctl start gns3.service

NEW_VERSION=$(gns3server --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
msg_ok "Updated successfully to version ${NEW_VERSION}!"
exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3080${CL}"
echo -e "${INFO}${YW} Connect your GNS3 GUI client to this server${CL}"
