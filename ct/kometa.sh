#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Kometa-Team/Kometa

APP="Kometa"
var_tags="${var_tags:-media;streaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d "/opt/kometa" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "kometa" "Kometa-Team/Kometa"; then
    msg_info "Stopping Service"
    systemctl stop kometa
    [[ -d "/opt/kometa-quickstart" ]] && systemctl stop kometa-quickstart
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    cp /opt/kometa/config/config.yml /opt
    msg_ok "Backup completed"

    PYTHON_VERSION="3.13" setup_uv
    fetch_and_deploy_gh_release "kometa" "Kometa-Team/Kometa" "tarball"

    msg_info "Updating Kometa"
    cd /opt/kometa
    [[ -d /opt/kometa/.venv ]] || $STD uv venv /opt/kometa/.venv
    $STD uv pip install -r requirements.txt -p /opt/kometa/.venv/bin/python
    mkdir -p config/assets
    cp /opt/config.yml config/config.yml
    msg_ok "Updated Kometa"

    msg_info "Starting Service"
    systemctl start kometa
    [[ -d "/opt/kometa-quickstart" ]] && systemctl start kometa-quickstart
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi

  if [[ -d "/opt/kometa-quickstart" ]] && check_for_gh_release "kometa-quickstart" "Kometa-Team/Quickstart"; then
    msg_info "Stopping Quickstart Service"
    systemctl stop kometa-quickstart
    msg_ok "Stopped Quickstart Service"

    fetch_and_deploy_gh_release "kometa-quickstart" "Kometa-Team/Quickstart" "tarball"

    msg_info "Updating Kometa Quickstart"
    cd /opt/kometa-quickstart
    $STD uv pip install -r requirements.txt -p /opt/kometa-quickstart/.venv/bin/python
    msg_ok "Updated Kometa Quickstart"

    msg_info "Starting Quickstart Service"
    systemctl start kometa-quickstart
    msg_ok "Started Quickstart Service"
    msg_ok "Updated Quickstart successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access Kometa Quickstart:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:7171${CL}"
