#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://pegaprox.com | https://github.com/PegaProx/project-pegaprox

APP="PegaProx"
var_tags="${var_tags:-proxmox;management;cluster}"
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

  if [[ ! -f /etc/systemd/system/pegaprox.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if check_for_gh_release "pegaprox" "PegaProx/project-pegaprox"; then
    msg_info "Stopping Service"
    systemctl stop pegaprox
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/PegaProx/config /opt/pegaprox_config_backup
    cp -r /opt/PegaProx/logs /opt/pegaprox_logs_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pegaprox" "PegaProx/project-pegaprox" "tarball" "latest" "/opt/PegaProx"

    msg_info "Restoring Data"
    cp -r /opt/pegaprox_config_backup/. /opt/PegaProx/config
    cp -r /opt/pegaprox_logs_backup/. /opt/PegaProx/logs 2>/dev/null || true
    rm -rf /opt/pegaprox_config_backup /opt/pegaprox_logs_backup
    msg_ok "Restored Data"

    msg_info "Updating Python Dependencies"
    cd /opt/PegaProx || exit
    $STD /opt/PegaProx/venv/bin/pip install -q -r requirements.txt
    msg_ok "Updated Python Dependencies"

    msg_info "Starting Service"
    systemctl start pegaprox
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:5000${CL}"
