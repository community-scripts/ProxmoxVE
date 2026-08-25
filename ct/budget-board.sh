#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/teelur/budget-board

APP="Budget-Board"
var_tags="${var_tags:-finance;budget;money}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/budget-board ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "budget-board" "teelur/budget-board"; then
    msg_info "Stopping Service"
    systemctl stop budget-board
    msg_ok "Stopped Service"

    create_backup /opt/budget-board/budget-board.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "budget-board" "teelur/budget-board" "tarball"

    restore_backup

    msg_info "Rebuilding Backend"
    cd /opt/budget-board/server
    $STD dotnet restore "BudgetBoard.WebAPI/BudgetBoard.WebAPI.csproj"
    export configuration=Release
    $STD dotnet publish "BudgetBoard.WebAPI/BudgetBoard.WebAPI.csproj" -c $configuration -o /opt/budget-board/publish /p:UseAppHost=false --no-restore
    msg_ok "Rebuilt Backend"

    msg_info "Rebuilding Frontend"
    cd /opt/budget-board/client
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    $STD yarn install
    $STD yarn run build
    cp -r dist/. /var/www/html/
    msg_ok "Rebuilt Frontend"

    msg_info "Starting Service"
    systemctl start budget-board
    nginx_enable_site budget-board.conf
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
