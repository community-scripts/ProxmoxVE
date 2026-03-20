#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: Heretek-AI
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/YaoApp/yao

APP="yao"
var_tags="${var_tags:-ai;agents;automation;low-code}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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

  if [[ ! -f /usr/local/bin/yao ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "yao" "YaoApp/yao"; then
    msg_info "Stopping Service"
    systemctl stop yao
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/yao/data /opt/yao_data_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    fetch_and_deploy_gh_release "yao" "YaoApp/yao" "singlefile" "latest" "/usr/local/bin" "yao-v*-linux-*"

    msg_info "Restoring Data"
    cp -r /opt/yao_data_backup/. /opt/yao/data 2>/dev/null || true
    rm -rf /opt/yao_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start yao
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5099${CL}"
