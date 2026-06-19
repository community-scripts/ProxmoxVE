#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wealthfolio.app/ | Github: https://github.com/wealthfolio/wealthfolio

APP="Wealthfolio"
var_tags="${var_tags:-finance;portfolio}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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

  if [[ ! -d /opt/wealthfolio ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if grep -q '^WF_CORS_ALLOW_ORIGINS=\*$' /opt/wealthfolio/.env; then
    sed -i "s|^WF_CORS_ALLOW_ORIGINS=\*$|WF_CORS_ALLOW_ORIGINS=http://${LOCAL_IP}:8080|" /opt/wealthfolio/.env
  fi

  if check_for_gh_release "wealthfolio" "wealthfolio/wealthfolio"; then
    msg_info "Stopping Service"
    systemctl stop wealthfolio
    msg_ok "Stopped Service"

    create_backup /opt/wealthfolio_data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wealthfolio" "wealthfolio/wealthfolio" "prebuild" "latest" "/opt/wealthfolio" "wealthfolio-server-*-linux-amd64.tar.gz"
    restore_backup
    install -m 755 /opt/wealthfolio/wealthfolio-server /usr/local/bin/wealthfolio-server


    msg_info "Starting Service"
    systemctl start wealthfolio
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
