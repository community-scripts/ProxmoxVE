#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zotregistry.dev/

APP="Zot-Registry"
var_tags="${var_tags:-registry;oci}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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

  if [[ ! -f /usr/bin/zot ]]; then
    msg_error "No ${APP} installation found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/project-zot/zot/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
  if [[ ! -f ~/.${APP} ]] || [[ "${RELEASE}" != "$(cat ~/.${APP})" ]]; then
    msg_info "Stopping Zot service"
    systemctl stop zot
    msg_ok "Stopped Zot service"

    msg_info "Updating Zot to ${RELEASE}"
    curl -fsSL "https://github.com/project-zot/zot/releases/download/${RELEASE}/zot-linux-amd64" -o /usr/bin/zot
    chmod +x /usr/bin/zot
    chown root:root /usr/bin/zot
    echo "${RELEASE}" >~/.${APP}
    systemctl restart zot
    msg_ok "Updated Zot to ${RELEASE}"
  else
    msg_ok "Zot is already up to date (${RELEASE})"
  fi

  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
