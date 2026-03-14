#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mudler/LocalRecall

APP="localrecall"
var_tags="${var_tags:-ai;rag;knowledge-base;vector-db}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /usr/local/bin/localrecall ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "localrecall" "mudler/LocalRecall"; then
    msg_info "Stopping Service"
    systemctl stop localrecall
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/localrecall/data /opt/localrecall_data_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    msg_info "Updating LocalRecall"
    setup_go
    fetch_and_deploy_gh_release "localrecall" "mudler/LocalRecall" "tarball" "latest" "/opt/localrecall"
    cd /opt/localrecall || exit
    $STD go build -o localrecall .
    mv localrecall /usr/local/bin/localrecall
    cd / || exit
    rm -rf /opt/localrecall
    msg_ok "Updated LocalRecall"

    msg_info "Restoring Data"
    mkdir -p /opt/localrecall/data
    mkdir -p /opt/localrecall/assets
    cp -r /opt/localrecall_data_backup/. /opt/localrecall/data 2>/dev/null || true
    rm -rf /opt/localrecall_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start localrecall
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
