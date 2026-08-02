#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: StellaeAlis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/writefreely/writefreely

APP="WriteFreely"
var_tags="${var_tags:-writing}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -d /opt/writefreely ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "writefreely" "writefreely/writefreely"; then
    msg_info "Stopping Services"
    systemctl stop writefreely
    msg_ok "Stopped Services"

    create_backup /opt/writefreely/keys /opt/writefreely/config.ini

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "writefreely" "writefreely/writefreely" "prebuild" "latest" "/opt/writefreely" "writefreely_*_linux_$(arch_resolve).tar.gz"

    restore_backup

    msg_info "Running Post-Update Tasks"
    cd /opt/writefreely
    $STD ./writefreely db migrate
    ln -s /opt/writefreely/writefreely /usr/local/bin/writefreely
    msg_ok "Ran Post-Update Tasks"

    msg_info "Starting Services"
    systemctl start writefreely
    msg_ok "Started Services"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
