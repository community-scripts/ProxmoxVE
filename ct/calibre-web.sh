#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: [YourGitHubUsername]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL e.g. https://github.com/example/app]

# ============================================================================
# APP CONFIGURATION
# ============================================================================
# These values are sent to build.func and define default container resources.
# Users can customize these during installation via the interactive prompts.
# ============================================================================

APP="Calibre-Web"
var_tags="${var_tags:-media;books}" # Max 2 tags, semicolon-separated
var_cpu="${var_cpu:-2}"                         # CPU cores: 1-4 typical
var_ram="${var_ram:-2048}"                      # RAM in MB: 512, 1024, 2048, etc.
var_disk="${var_disk:-8}"                       # Disk in GB: 6, 8, 10, 20 typical
var_os="${var_os:-debian}"                      # OS: debian, ubuntu, alpine
var_version="${var_version:-13}"                # OS Version: 13 (Debian), 24.04 (Ubuntu), 3.21 (Alpine)
var_unprivileged="${var_unprivileged:-1}"       # 1=unprivileged (secure), 0=privileged (for Docker/Podman)

# ============================================================================
# INITIALIZATION - These are required in all CT scripts
# ============================================================================
header_info "$APP" # Display app name and setup header
variables          # Initialize build.func variables
color              # Load color variables for output
catch_errors       # Enable error handling with automatic exit on failure

# ============================================================================
# UPDATE SCRIPT - Called when user selects "Update" from web interface
# ============================================================================
# This function is triggered by the web interface to update the application.
# It should:
#   1. Check if installation exists
#   2. Check for new GitHub releases
#   3. Stop running services
#   4. Backup critical data
#   5. Deploy new version
#   6. Run post-update commands (migrations, config updates, etc.)
#   7. Restore data if needed
#   8. Start services
#
# Exit with `exit` at the end to prevent container restart.
# ============================================================================

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # Step 1: Verify installation exists
  if [[ ! -d /opt/calibre-web ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Step 2: Check if update is available
  if check_for_gh_release "calibre-web" "janeczku/calibre-web"; then

    # Step 3: Stop services before update
    msg_info "Stopping Service"
    systemctl stop calibre-web
    msg_ok "Stopped Service"

    # Step 4: Backup critical data before overwriting
    msg_info "Backing up Data"
    cp -r /opt/calibre-web/app.db /opt/calibre-web/app.db_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    # Step 5: Download and deploy new version
    # CLEAN_INSTALL=1 removes old directory before extracting
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "calibre-web" "janeczku/calibre-web" "tarball" "latest" "/opt/calibre-web"

    # Step 6: Install Python dependencies
    msg_info "Installing Dependencies"
    cd /opt/calibre-web
    $STD pip3 install --no-cache-dir -r requirements.txt
    msg_ok "Installed Dependencies"
    # $STD composer install --no-dev
    # msg_ok "Installed Dependencies"

    # Step 7: Restore data from backup
    msg_info "Restoring Data"
    cp /opt/calibre-web/app.db_backup /opt/calibre-web/app.db 2>/dev/null || true
    rm -f /opt/calibre-web/app.db_backup
    msg_ok "Restored Data"

    # Step 8: Restart service with new version
    msg_info "Starting Service"
    systemctl start calibre-web
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

# ============================================================================
# MAIN EXECUTION - Container creation flow
# ============================================================================
# These are called by build.func and handle the full installation process:
#   1. start              - Initialize container creation
#   2. build_container    - Execute the install script inside container
#   3. description        - Display completion info and access details
# ============================================================================

start
build_container
description

# ============================================================================
# COMPLETION MESSAGE
# ============================================================================
msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8083${CL}"
