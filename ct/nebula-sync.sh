#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: gabriel403
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lovelaze/nebula-sync

APP="Nebula-Sync"
var_tags="${var_tags:-dns;sync}"
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
  if [[ ! -f /opt/nebula-sync/nebula-sync ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/lovelaze/nebula-sync/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
  if [[ ! -f /opt/nebula-sync_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/nebula-sync_version.txt)" ]]; then
    msg_info "Updating Nebula-Sync to v${RELEASE}"
    if [[ -f /usr/local/bin/update_nebula-sync ]]; then
      /usr/local/bin/update_nebula-sync
    else
      msg_error "Update script not found!"
      exit
    fi
    msg_ok "Updated Nebula-Sync"
  else
    msg_ok "No update required. Nebula-Sync is already at v${RELEASE}."
  fi
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Nebula-Sync is now running and will synchronize your Pi-hole instances.${CL}"
