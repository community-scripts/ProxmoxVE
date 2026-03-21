#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Matthew Stern (sternma) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dmunozv04/iSponsorBlockTV

APP="iSponsorBlockTV"
var_tags="${var_tags:-media;automation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/isponsorblocktv ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "isponsorblocktv" "dmunozv04/iSponsorBlockTV"; then
    msg_info "Stopping Service"
    systemctl stop isponsorblocktv
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "isponsorblocktv" "dmunozv04/iSponsorBlockTV" "singlefile" "latest" "/opt/isponsorblocktv" "iSponsorBlockTV-x86_64-linux"

    msg_info "Starting Service"
    systemctl start isponsorblocktv
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
echo -e "${INFO}${YW} Run the setup wizard inside the container with:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}iSponsorBlockTV setup${CL}"
