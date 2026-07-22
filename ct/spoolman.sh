#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Donkie/Spoolman

APP="Spoolman"
var_tags="${var_tags:-3d-printing}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/spoolman ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  PYTHON_VERSION="3.14" setup_uv

  if check_for_gh_release "spoolman" "Donkie/Spoolman"; then
    msg_info "Stopping Service"
    systemctl stop spoolman
    msg_ok "Stopped Service"

    create_backup /opt/spoolman/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "spoolman" "Donkie/Spoolman" "prebuild" "latest" "/opt/spoolman" "spoolman.zip"

    restore_backup

    msg_info "Updating Spoolman"
    cd /opt/spoolman
    $STD uv sync --locked --no-install-project
    $STD uv sync --locked
    sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bash /opt/spoolman/scripts/start.sh|' /etc/systemd/system/spoolman.service
    msg_ok "Updated Spoolman"

    msg_info "Starting Service"
    systemctl start spoolman
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:7912${CL}"
