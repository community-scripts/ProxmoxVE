#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ombi.io/ | Github: https://github.com/Ombi-app/Ombi

APP="Ombi"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/ombi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "ombi" "Ombi-app/Ombi"; then
    msg_info "Stopping Service"
    systemctl stop ombi
    msg_ok "Stopped Service"

    create_backup /opt/ombi/Ombi.db /opt/ombi/OmbiExternal.db /opt/ombi/OmbiSettings.db /opt/ombi/database.json

    rm -rf /opt/ombi
    fetch_and_deploy_gh_release "ombi" "Ombi-app/Ombi" "prebuild" "latest" "/opt/ombi" "linux-x64.tar.gz"
    restore_backup

    msg_info "Starting Service"
    systemctl start ombi
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
echo -e "${GATEWAY}${BGN}http://${IP}:5000${CL}"
