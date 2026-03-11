#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL ""${COMMUNITY_SCRIPTS_URL"}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mcmonkeyprojects/SwarmUI

APP="SwarmUI"
var_tags="${var_tags:-ai}"
var_cpu="${var_cpu:-8}"
var_ram="${var_ram:-16384}"
var_disk="${var_disk:-50}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/swarmui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  cd /opt/swarmui
  LOCAL_VERSION=$(git rev-parse HEAD)
  REMOTE_VERSION=$(git ls-remote origin HEAD | awk '{print $1}')

  if [[ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]]; then
    msg_info "Stopping Service"
    systemctl stop swarmui
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/swarmui/Data /opt/swarmui_data_backup
    cp -r /opt/swarmui/Models /opt/swarmui_models_backup 2>/dev/null || true
    cp -r /opt/swarmui/Output /opt/swarmui_output_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    msg_info "Updating SwarmUI"
    $STD git fetch origin
    $STD git reset --hard origin/main
    msg_ok "Updated SwarmUI"

    msg_info "Rebuilding SwarmUI"
    $STD dotnet build src/SwarmUI.csproj --configuration Release -o ./bin
    msg_ok "Rebuilt SwarmUI"

    msg_info "Restoring Data"
    cp -r /opt/swarmui_data_backup/. /opt/swarmui/Data/
    cp -r /opt/swarmui_models_backup/. /opt/swarmui/Models/ 2>/dev/null || true
    cp -r /opt/swarmui_output_backup/. /opt/swarmui/Output/ 2>/dev/null || true
    rm -rf /opt/swarmui_data_backup /opt/swarmui_models_backup /opt/swarmui_output_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start swarmui
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_info "No update required. SwarmUI is already up to date."
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7801${CL}"
