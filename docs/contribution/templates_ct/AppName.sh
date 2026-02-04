#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: [YourGitHubUsername]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL e.g. https://github.com/example/app]

# App Default Values
APP="[AppName]"
var_tags="${var_tags:-[category]}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

# =============================================================================
# CONFIGURATION GUIDE
# =============================================================================
# APP           - Display name, title case (e.g. "Koel", "Wallabag", "Actual Budget")
# var_tags      - Max 2 tags, semicolon separated (e.g. "music;streaming", "finance")
# var_cpu       - CPU cores: 1-4 typical
# var_ram       - RAM in MB: 512, 1024, 2048, 4096 typical
# var_disk      - Disk in GB: 4, 6, 8, 10, 20 typical
# var_os        - OS: debian, ubuntu, alpine
# var_version   - OS version: 12/13 (debian), 22.04/24.04 (ubuntu), 3.20/3.21 (alpine)
# var_unprivileged - 1 = unprivileged (secure, default), 0 = privileged (for docker etc.)

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # Check if installation exists
  if [[ ! -d /opt/[appname] ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # check_for_gh_release returns 0 (true) if update available, 1 (false) if not
  if check_for_gh_release "[appname]" "[owner/repo]"; then
    msg_info "Stopping Services"
    systemctl stop [appname]
    msg_ok "Stopped Services"

    # Optional: Backup important data before update
    msg_info "Creating Backup"
    mkdir -p /tmp/[appname]_backup
    cp /opt/[appname]/.env /tmp/[appname]_backup/ 2>/dev/null || true
    cp -r /opt/[appname]/data /tmp/[appname]_backup/ 2>/dev/null || true
    msg_ok "Created Backup"

    # CLEAN_INSTALL=1 removes old directory before extracting new version
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "[appname]" "[owner/repo]" "tarball" "latest" "/opt/[appname]"

    # Restore configuration and data
    msg_info "Restoring Data"
    cp /tmp/[appname]_backup/.env /opt/[appname]/ 2>/dev/null || true
    cp -r /tmp/[appname]_backup/data/* /opt/[appname]/data/ 2>/dev/null || true
    rm -rf /tmp/[appname]_backup
    msg_ok "Restored Data"

    # Optional: Run any post-update commands
    msg_info "Running Post-Update Tasks"
    cd /opt/[appname] 
    # Examples:
    # $STD npm ci --production
    # $STD php artisan migrate --force
    # $STD composer install --no-dev
    msg_ok "Ran Post-Update Tasks"

    msg_info "Starting Services"
    systemctl start [appname]
    msg_ok "Started Services"

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
