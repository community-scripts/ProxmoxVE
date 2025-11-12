#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://signoz.io/

APP="SigNoz"
var_tags="${var_tags:-notes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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
  if [[ ! -d /opt/signoz ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "signoz" "SigNoz/signoz"; then
    msg_info "Stopping Services"
    systemctl stop signoz
    systemctl stop signoz-otel-collector
    msg_ok "Stopped Services"

    fetch_and_deploy_gh_release "signoz" "SigNoz/signoz" "prebuild" "latest" "/opt/signoz" "signoz-community_linux_amd64.tar.gz"
    fetch_and_deploy_gh_release "signoz-otel-collector" "SigNoz/signoz-otel-collector" "prebuild" "latest" "/opt/signoz-otel-collector" "signoz-otel-collector_linux_amd64.tar.gz"
    fetch_and_deploy_gh_release "signoz-schema-migrator" "SigNoz/signoz-otel-collector" "prebuild" "latest" "/opt/signoz-schema-migrator" "signoz-schema-migrator_linux_amd64.tar.gz"

    msg_info "Updating ${APP}"
    cd /opt/signoz-schema-migrator/bin
    $STD ./signoz-schema-migrator sync --dsn="tcp://localhost:9000?password=" --replication=true --up=
    $STD ./signoz-schema-migrator async --dsn="tcp://localhost:9000?password=" --replication=true --up=
    msg_ok "Updated $APP"

    msg_info "Starting Services"
    systemctl start signoz-otel-collector
    systemctl start signoz
    msg_ok "Started Services"
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
