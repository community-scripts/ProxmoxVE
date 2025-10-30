#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.ispyconnect.com/

APP="AgentDVR"
var_tags="${var_tags:-dvr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/agentdvr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL "https://www.ispyconnect.com/api/Agent/DownloadLocation4?platform=Linux64&fromVersion=0" | grep -o 'https://.*\.zip')
  if [[ "${RELEASE}" != "$(cat ~/.agentdvr 2>/dev/null)" ]] || [[ ! -f ~/.agentdvr ]]; then
    msg_info "Stopping service"
    systemctl stop AgentDVR
    msg_ok "Service stopped"

    msg_info "Updating $APP"
    cd /opt/agentdvr/agent
    curl -fsSL "$RELEASE" -o $(basename "$RELEASE")
    $STD unzip -o Agent_Linux64*.zip
    chmod +x ./Agent
    echo $RELEASE >~/.agentdvr
    rm -rf Agent_Linux64*.zip
    msg_ok "Updated $APP"

    msg_info "Starting service"
    systemctl start AgentDVR
    msg_ok "Service started"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8090${CL}"
