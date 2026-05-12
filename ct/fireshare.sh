#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ShaneIsrael/fireshare

APP="Fireshare"
var_tags="${var_tags:-sharing;video}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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
  if [[ ! -d /opt/fireshare ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "fireshare" "ShaneIsrael/fireshare"; then
    msg_info "Stopping Service"
    systemctl stop fireshare
    msg_ok "Stopped Service"

    mv /opt/fireshare/fireshare.env /opt
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "fireshare" "ShaneIsrael/fireshare" "tarball"
    mv /opt/fireshare.env /opt/fireshare
    rm -f /usr/local/bin/fireshare

    msg_info "Updating Fireshare"
    cd /opt/fireshare
    $STD uv venv --clear
    $STD .venv/bin/python -m ensurepip --upgrade
    $STD .venv/bin/python -m pip install --upgrade --break-system-packages pip
    $STD .venv/bin/python -m pip install --no-cache-dir --break-system-packages --ignore-installed app/server
    cp .venv/bin/fireshare /usr/local/bin/fireshare
    export FLASK_APP="/opt/fireshare/app/server/fireshare:create_app()"
    export DATA_DIRECTORY=/opt/fireshare-data
    export IMAGE_DIRECTORY=/opt/fireshare-images
    export VIDEO_DIRECTORY=/opt/fireshare-videos
    export PROCESSED_DIRECTORY=/opt/fireshare-processed
    $STD uv run flask db upgrade
    msg_ok "Updated Fireshare"

    msg_info "Starting Service"
    systemctl start fireshare
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  cleanup_lxc

  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
