#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Maintainerr/Maintainerr

APP="Maintainerr"
var_tags="${var_tags:-media;arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d /opt/app ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "maintainerr" "Maintainerr/Maintainerr"; then
    msg_info "Stopping Service"
    systemctl stop maintainerr
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/data /opt/maintainerr_data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "maintainerr" "Maintainerr/Maintainerr" "tarball" "latest" "/opt/app"

    msg_info "Installing Dependencies"
    cd /opt/app || exit
    $STD corepack enable
    $STD corepack prepare yarn@4.11.0 --activate
    $STD yarn install --network-timeout 99999999
    msg_ok "Installed Dependencies"

    msg_info "Building Application"
    $STD yarn turbo build
    msg_ok "Built Application"

    msg_info "Installing Production Dependencies"
    $STD yarn workspaces focus --all --production
    msg_ok "Installed Production Dependencies"

    msg_info "Restoring Data"
    cp -r /opt/maintainerr_data_backup/. /opt/data/
    rm -rf /opt/maintainerr_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start maintainerr
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6246${CL}"
