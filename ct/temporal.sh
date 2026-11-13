#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Renan Bastos (renanbastos93)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/temporalio/temporal

APP="Temporal"
var_tags="${var_tags:-workflow;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}" # unset = ask the user; server, UI and CLI all ship linux_arm64 assets, but not yet run on arm64
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/temporal ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "temporal" "temporalio/temporal"; then
    msg_info "Stopping Temporal"
    systemctl stop temporal-ui temporal
    msg_ok "Stopped Temporal"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "temporal" "temporalio/temporal" "prebuild" "latest" "/opt/temporal" "temporal_*_linux_$(arch_resolve).tar.gz"

    msg_info "Migrating Temporal Database"
    set -a && source /etc/temporal/temporal.env && set +a
    $STD /opt/temporal/temporal-sql-tool --db temporal update-schema --schema-name postgresql/v12/temporal
    $STD /opt/temporal/temporal-sql-tool --db temporal_visibility update-schema --schema-name postgresql/v12/visibility
    msg_ok "Migrated Temporal Database"

    msg_info "Starting Temporal"
    systemctl start temporal temporal-ui
    msg_ok "Started Temporal"
    msg_ok "Updated Temporal successfully!"
  fi

  if check_for_gh_release "temporal-ui" "temporalio/ui-server"; then
    msg_info "Stopping Temporal UI"
    systemctl stop temporal-ui
    msg_ok "Stopped Temporal UI"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "temporal-ui" "temporalio/ui-server" "prebuild" "latest" "/opt/temporal-ui" "ui-server_*_linux_$(arch_resolve).tar.gz"

    msg_info "Starting Temporal UI"
    systemctl start temporal-ui
    msg_ok "Started Temporal UI"
    msg_ok "Updated Temporal UI successfully!"
  fi

  if check_for_gh_release "temporal-cli" "temporalio/cli"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "temporal-cli" "temporalio/cli" "prebuild" "latest" "/opt/temporal-cli" "temporal_cli_*_linux_$(arch_resolve).tar.gz"
    msg_ok "Updated Temporal CLI successfully!"
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
echo -e "${INFO}${YW}gRPC endpoint for workers and SDKs: ${IP}:7233${CL}"
