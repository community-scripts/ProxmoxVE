#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: sdblepas
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sdblepas/CinePlete

APP="CinePlete"
var_tags="${var_tags:-media;plex;jellyfin}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/cineplete ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "cineplete" "sdblepas/CinePlete"; then
    msg_info "Stopping Service"
    systemctl stop cineplete
    msg_ok "Stopped Service"

    msg_info "Updating ${APP}"
    fetch_and_deploy_gh_release "cineplete" "sdblepas/CinePlete" "tarball" "latest" "/opt/cineplete"
    /opt/cineplete/.venv/bin/pip install --quiet --upgrade pip
    /opt/cineplete/.venv/bin/pip install --quiet -r /opt/cineplete/requirements.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start cineplete
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7474${CL}"
