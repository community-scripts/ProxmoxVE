#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lingarr-translate/lingarr

APP="Lingarr"
var_tags="${var_tags:-arr;subtitles}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/lingarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "lingarr" "lingarr-translate/lingarr"; then
    msg_info "Stopping Service"
    systemctl stop lingarr
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "lingarr" "lingarr-translate/lingarr" "tarball"

    msg_info "Building Lingarr (Patience)"
    cd /opt/lingarr/Lingarr.Client
    $STD npm ci
    $STD npm run build
    mkdir -p /opt/lingarr/Lingarr.Server/wwwroot
    cp -r /opt/lingarr/Lingarr.Client/dist/* /opt/lingarr/Lingarr.Server/wwwroot/
    cd /opt/lingarr
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    rm -rf /opt/lingarr_app
    $STD dotnet publish ./Lingarr.Server/Lingarr.Server.csproj -c Release -o /opt/lingarr_app /p:UseAppHost=false /p:Version="$(cat ~/.lingarr)"
    msg_ok "Built Lingarr"

    msg_info "Starting Service"
    systemctl start lingarr
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
echo -e "${GATEWAY}${BGN}http://${IP}:9876${CL}"
echo -e "${INFO}${YW}Set your translation backend in /opt/lingarr.env${CL}"
