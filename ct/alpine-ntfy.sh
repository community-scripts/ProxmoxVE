#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: cobalt (cobaltgit)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://ntfy.sh/

APP="Alpine-ntfy"
var_tags="${var_tags:-notification}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  if [[ ! -d /etc/ntfy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ntfy LXC"
  $STD apk -U upgrade
  setcap 'cap_net_bind_service=+ep' /usr/bin/ntfy
  msg_ok "Updated ntfy LXC"

  msg_info "Restarting ntfy"
  rc-service ntfy restart
  msg_ok "Restarted ntfy"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
