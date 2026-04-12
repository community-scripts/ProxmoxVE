#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wakapi.dev/ | https://github.com/muety/wakapi

APP="Alpine-Wakapi"
var_tags="${var_tags:-code;time-tracking}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  if [[ ! -d /opt/wakapi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -s https://api.github.com/repos/muety/wakapi/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [ "${RELEASE}" != "$(cat ~/.wakapi 2>/dev/null)" ] || [ ! -f ~/.wakapi ]; then
    msg_info "Stopping Wakapi Service"
    $STD rc-service wakapi stop
    msg_ok "Stopped Wakapi Service"

    msg_info "Updating Wakapi LXC"
    $STD apk -U upgrade
    msg_ok "Updated Wakapi LXC"

    msg_info "Creating backup"
    mkdir -p /opt/wakapi-backup
    cp /opt/wakapi/config.yml /opt/wakapi/wakapi_db.db /opt/wakapi-backup/
    msg_ok "Created backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wakapi" "muety/wakapi" "prebuild" "latest" "/opt/wakapi" "wakapi_linux_amd64.zip"

    msg_info "Configuring Wakapi"
    cd /opt/wakapi
    cp /opt/wakapi-backup/config.yml /opt/wakapi/
    cp /opt/wakapi-backup/wakapi_db.db /opt/wakapi/
    rm -rf /opt/wakapi-backup
    msg_ok "Configured Wakapi"

    msg_info "Starting Service"
    $STD rc-service wakapi start
    msg_ok "Started Service"
    msg_ok "Updated successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit 0
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
