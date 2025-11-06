#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Jackett/Jackett

APP="Jackett"
var_tags="${var_tags:-torrent}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -f /etc/systemd/system/jackett.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "Jackett" "Jackett/Jackett"; then
    if [ ! -f /opt/.env ]; then
      sed -i 's|^Environment="DisableRootWarning=true"$|EnvironmentFile="/opt/.env"|' /etc/systemd/system/jackett.service
      cat <<EOF >/opt/.env
DisableRootWarning=true
EOF
    fi

    msg_info "Stopping Service"
    systemctl stop jackett
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jackett" "Jackett/Jackett" "prebuild" "latest" "/opt/Jackett" "Jackett.Binaries.LinuxAMDx64.tar.gz"

    msg_info "Starting Service"
    systemctl start jackett
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9117${CL}"
