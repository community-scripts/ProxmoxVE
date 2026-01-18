#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: [YourGitHubUsername]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL e.g. https://github.com/example/app]

# App Default Values
APP="[AppName]"
var_tags="${var_tags:-[category1];[category2]}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

# =============================================================================
# CONFIGURATION GUIDE
# =============================================================================
# APP           - Display name, title case (e.g. "Koel", "Wallabag", "Actual Budget")
# var_tags      - Max 2 tags, semicolon separated (e.g. "music;streaming", "finance")
# var_cpu       - CPU cores: 1-4 typical, 4+ for heavy apps
# var_ram       - RAM in MB: 512, 1024, 2048, 4096, 8192 typical
# var_disk      - Disk in GB: 6, 8, 10, 20 typical (more for data-heavy apps)
# var_os        - OS: debian, ubuntu, alpine
# var_version   - OS version: 13 (debian), 24.04 (ubuntu), 3.21 (alpine)
# var_unprivileged - 1 = unprivileged (secure, default), 0 = privileged (for podman/docker)

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/[appname] ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "[appname]" "[owner/repo]"; then
    msg_info "Stopping Service"
    systemctl stop [appname]
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/[appname]/data /opt/[appname]_data_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "[appname]" "[owner/repo]" "tarball" "latest" "/opt/[appname]"

    msg_info "Restoring Data"
    cp -r /opt/[appname]_data_backup/. /opt/[appname]/data/ 2>/dev/null || true
    rm -rf /opt/[appname]_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start [appname]
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:[PORT]${CL}"
