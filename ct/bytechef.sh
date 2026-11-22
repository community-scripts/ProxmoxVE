#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bytechefhq/bytechef

APP="ByteChef"
var_tags="${var_tags:-automation;workflow;integration}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/bytechef ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "bytechef" "bytechefhq/bytechef"; then
    msg_info "Stopping ByteChef"
    systemctl stop bytechef
    msg_ok "Stopped ByteChef"

    JAVA_VERSION="25" setup_java
    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bytechef" "bytechefhq/bytechef" "tarball"

    msg_info "Building ByteChef (Patience)"
    mv /opt/bytechef /opt/bytechef-build
    cd /opt/bytechef-build/client
    $STD npm ci
    $STD npm run build
    cd /opt/bytechef-build
    $STD ./gradlew --no-daemon :server:apps:server-app:bootJar -Pprod -Pkotlin.compiler.execution.strategy=in-process
    mkdir -p /opt/bytechef/server
    mv /opt/bytechef-build/server/apps/server-app/build/libs/server-app-*.jar /opt/bytechef/server/server-app.jar
    mv /opt/bytechef-build/client/dist /opt/bytechef/client
    rm -rf /opt/bytechef-build
    msg_ok "Built ByteChef"

    msg_info "Starting ByteChef"
    systemctl start bytechef
    msg_ok "Started ByteChef"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
