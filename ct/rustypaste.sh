#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: GoldenSpringness
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/orhun/rustypaste

APP="rustypaste"
var_tags="${var_tags:-pastebin;storage}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -f /opt/rustypaste/rustypaste ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "rustypaste" "orhun/rustypaste"; then
    msg_info "Stopping Services"
    systemctl stop rustypaste
    msg_ok "Stopped Services"

    msg_info "Creating Backup"
    tar -czf "/opt/rustypaste_backup_$(date +%F).tar.gz" /opt/rustypaste/upload 2>/dev/null || true
    cp /opt/rustypaste/config.toml /tmp/rustypaste_config.toml.bak
    msg_ok "Backup Created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "rustypaste" "orhun/rustypaste" "prebuild" "latest" "/opt/rustypaste" "*x86_64-unknown-linux-gnu.tar.gz"

    msg_info "Restoring Data"
    mv /tmp/rustypaste_config.toml.bak /opt/rustypaste/config.toml
    tar -xzf "/opt/rustypaste_backup_$(date +%F).tar.gz" -C /opt/rustypaste/upload 2>/dev/null || true
    rm -rf /opt/rustypaste_backup_$(date +%F).tar.gz
    msg_ok "Restored Data"

    msg_info "Starting Services"
    systemctl start rustypaste
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi

  if check_for_gh_release "rustypaste-cli" "orhun/rustypaste-cli"; then
    fetch_and_deploy_gh_release "rustypaste-cli" "orhun/rustypaste-cli" "prebuild" "latest" "/usr/local/bin" "*x86_64-unknown-linux-gnu.tar.gz"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}rustypaste setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
