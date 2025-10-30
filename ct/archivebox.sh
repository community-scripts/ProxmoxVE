#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://archivebox.io/

APP="ArchiveBox"
var_tags="${var_tags:-archive;bookmark}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/archivebox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="@postlight/parser@latest,single-file-cli@latest" setup_nodejs
  PYTHON_VERSION="3.13" setup_uv

  if ! dpkg -l | grep -q "^ii  chromium "; then
    msg_info "Installing System Dependencies"
    $STD apt-get install -y chromium
    msg_ok "Installed System Dependencies"
  fi

  msg_info "Stopping Service"
  systemctl stop archivebox
  msg_ok "Stopped Service"

  msg_info "Upgrading Playwright"
  $STD uv pip install playwright --system
  $STD playwright install-deps chromium
  msg_ok "Upgraded Playwright"

  msg_info "Updating ArchiveBox"
  cd /opt/archivebox/data
  $STD uv pip install --system --upgrade --no-reinstall archivebox
  sudo -u archivebox archivebox init
  msg_ok "Updated ArchiveBox"

  msg_info "Starting Service"
  systemctl start archivebox
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000/admin/login${CL}"
