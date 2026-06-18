#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://0xerr0r.github.io/blocky | Github: https://github.com/0xERR0R/blocky

APP="Blocky"
var_tags="${var_tags:-adblock}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -d /opt/blocky ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "blocky" "0xERR0R/blocky"; then
    msg_info "Stopping Service"
    systemctl stop blocky
    msg_ok "Stopped Service"

    create_backup /opt/blocky/config.yml
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "blocky" "0xERR0R/blocky" "prebuild" "latest" "/opt/blocky" "blocky_*_Linux_$(arch_resolve "x86_64" "arm64").tar.gz"
    restore_backup

    msg_info "Starting Service"
    systemctl start blocky
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"