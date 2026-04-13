#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/actions/runner

APP="GitHub-Runner"
var_tags="${var_tags:-ci}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_nesting="${var_nesting:-1}"
var_keyctl="${var_keyctl:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/actions-runner/run.sh ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if check_for_gh_release "actions-runner" "actions/runner"; then
    msg_info "Stopping Service"
    systemctl stop actions-runner
    msg_ok "Stopped Service"

    msg_info "Backing up runner configuration"
    BACKUP_DIR="/opt/actions-runner.backup"
    mkdir -p "$BACKUP_DIR"
    for f in .runner .credentials .credentials_rsaparams .env .path; do
      [[ -f /opt/actions-runner/$f ]] && cp -a /opt/actions-runner/$f "$BACKUP_DIR/"
    done
    msg_ok "Backed up configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "actions-runner" "actions/runner" "prebuild" "latest" "/opt/actions-runner" "actions-runner-linux-x64-*.tar.gz"

    msg_info "Restoring runner configuration"
    for f in .runner .credentials .credentials_rsaparams .env .path; do
      [[ -f "$BACKUP_DIR/$f" ]] && cp -a "$BACKUP_DIR/$f" /opt/actions-runner/
    done
    rm -rf "$BACKUP_DIR"
    msg_ok "Restored configuration"

    msg_info "Starting Service"
    systemctl start actions-runner
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
echo -e "${INFO}${YW} After first boot, run config.sh with your token and start the service.${CL}"
