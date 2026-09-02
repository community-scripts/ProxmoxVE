#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Ozark-Connect/NetworkOptimizer

APP="NetworkOptimizer"
var_tags="${var_tags:-network;monitoring;unifi}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
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

  if [[ ! -d /opt/networkoptimizer ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "networkoptimizer" "Ozark-Connect/NetworkOptimizer"; then
    msg_info "Stopping Service"
    systemctl stop networkoptimizer
    msg_ok "Stopped Service"

    create_backup /opt/networkoptimizer/networkoptimizer.env
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "networkoptimizer" "Ozark-Connect/NetworkOptimizer" "tarball"
    GO_VERSION="$(grep -m1 '^go ' /opt/networkoptimizer/src/uwnspeedtest/go.mod | awk '{print $2}')" setup_go
    restore_backup

    msg_info "Rebuilding NetworkOptimizer"
    RID="linux-x64"
    [[ "$(dpkg --print-architecture)" == "arm64" ]] && RID="linux-arm64"
    cd /opt/networkoptimizer
    export MSBUILDDISABLENODEREUSE=1
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SYSTEM_NET_DISABLEIPV6=1
    $STD dotnet publish src/NetworkOptimizer.Web -c Release -r "$RID" --self-contained -o /opt/networkoptimizer/publish
    chmod +x /opt/networkoptimizer/publish/NetworkOptimizer.Web
    mkdir -p /opt/networkoptimizer/publish/tools
    cd /opt/networkoptimizer/src/uwnspeedtest
    CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $STD go build -trimpath -ldflags "-s -w" -o /opt/networkoptimizer/publish/tools/uwnspeedtest-linux-arm64 .
    [[ "$(arch_resolve)" != "arm64" ]] && CGO_ENABLED=0 GOOS=linux GOARCH="$(arch_resolve)" $STD go build -trimpath -ldflags "-s -w" -o "/opt/networkoptimizer/publish/tools/uwnspeedtest-linux-$(arch_resolve)" .
    msg_ok "Rebuilt NetworkOptimizer"

    msg_info "Starting Service"
    systemctl start networkoptimizer
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
echo -e "${GATEWAY}${BGN}http://${IP}:8042${CL}"
