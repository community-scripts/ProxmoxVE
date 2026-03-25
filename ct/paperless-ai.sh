#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clusterzx/paperless-ai

APP="Paperless-AI"
var_tags="${var_tags:-ai;document}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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
  if [[ ! -d /opt/paperless-ai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "paperless-ai" "clusterzx/paperless-ai"; then
    msg_info "Stopping Service"
    systemctl stop paperless-ai paperless-rag
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    cp -r /opt/paperless-ai/data /opt/paperless-ai-data-backup
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "paperless-ai" "clusterzx/paperless-ai" "tarball"

    msg_info "Restoring data"
    cp -r /opt/paperless-ai-data-backup/* /opt/paperless-ai/data/
    rm -rf /opt/paperless-ai-data-backup
    msg_ok "Restored data"

    msg_info "Updating Paperless-AI"
    cd /opt/paperless-ai
    if [[ ! -d /opt/paperless-ai/venv ]]; then
      msg_info "Recreating Python venv"
      $STD python3 -m venv /opt/paperless-ai/venv
    fi
    source /opt/paperless-ai/venv/bin/activate
    $STD pip install --upgrade pip
    $STD pip install --no-cache-dir -r requirements.txt
    mkdir -p data/chromadb
    $STD npm ci --only=production
    msg_ok "Updated Paperless-AI"

    msg_info "Starting Service"
    systemctl start paperless-rag
    sleep 3
    systemctl start paperless-ai
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
