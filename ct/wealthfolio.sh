#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wealthfolio.app/

APP="Wealthfolio"
var_tags="${var_tags:-finance;portfolio}"
var_cpu="${var_cpu:-4}"
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

  if [[ ! -d /opt/wealthfolio ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "wealthfolio" "afadil/wealthfolio"; then
    msg_info "Stopping Service"
    systemctl stop wealthfolio
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/wealthfolio_data /opt/wealthfolio_data_backup
    cp /opt/wealthfolio/.env /opt/wealthfolio_env_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wealthfolio" "afadil/wealthfolio" "tarball"

    msg_info "Building Frontend (patience)"
    cd /opt/wealthfolio
    $STD pnpm install --frozen-lockfile
    $STD pnpm tsc
    $STD pnpm vite build
    msg_ok "Built Frontend"

    msg_info "Building Backend (patience)"
    cd /opt/wealthfolio/src-server
    source ~/.cargo/env
    $STD cargo build --release --manifest-path Cargo.toml
    cp /opt/wealthfolio/src-server/target/release/wealthfolio-server /usr/local/bin/wealthfolio-server
    chmod +x /usr/local/bin/wealthfolio-server
    msg_ok "Built Backend"

    msg_info "Restoring Data"
    cp -r /opt/wealthfolio_data_backup/. /opt/wealthfolio_data
    cp /opt/wealthfolio_env_backup /opt/wealthfolio/.env
    rm -rf /opt/wealthfolio_data_backup /opt/wealthfolio_env_backup
    msg_ok "Restored Data"

    msg_info "Cleaning Up"
    rm -rf /opt/wealthfolio/src-server/target
    rm -rf /root/.cargo/registry
    rm -rf /opt/wealthfolio/node_modules
    msg_ok "Cleaned Up"

    msg_info "Starting Service"
    systemctl start wealthfolio
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
