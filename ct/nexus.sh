#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/footgod-alt/ProxmoxVE-Nexus/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Footgod-alt
# License: MIT | https://github.com/footgod-alt/ProxmoxVE-Nexus/raw/main/LICENSE
# Source: https://github.com/sonatype/nexus-public

# ============================================================================
# APP CONFIGURATION
# ============================================================================
# These values are sent to build.func and define default container resources.
# Users can customize these during installation via the interactive prompts.
# ============================================================================

APP="Nexus Repository Manager OSS"          # App name displayed during installation
var_tags="${var_tags:-repository-manager;nexus3}" # Max 2 tags, semicolon-separated
var_cpu="${var_cpu:-2}"                         # CPU cores: 1-4 typical
var_ram="${var_ram:-2048}"                      # RAM in MB: 512, 1024, 2048, etc.
var_disk="${var_disk:-8}"                       # Disk in GB: 6, 8, 10, 20 typical
var_os="${var_os:-debian}"                      # OS: debian, ubuntu, alpine
var_version="${var_version:-13}"                # OS Version: 13 (Debian), 24.04 (Ubuntu), 3.21 (Alpine)
var_unprivileged="${var_unprivileged:-1}"       # 1=unprivileged (secure), 0=privileged (for Docker/Podman)

# ====================
# INITIALIZATION
# ====================
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
  if [[ ! -d /opt/nexus ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  installed_version=$(cat /opt/nexus/version.txt 2>/dev/null || echo "unknown")
  LATEST_VERSION=$(curl -s "https://api.github.com/repos/sonatype/nexus-public/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  # Step 2: Check if update is available
  if [[ "$installed_version" != "$LATEST_VERSION" ]]; then

    # Step 3: Stop services before update
    msg_info "Stopping Service"
    systemctl stop nexus
    msg_ok "Stopped Service"

    # Step 4: Backup critical data before overwriting
    msg_info "Backing up Old Version"
    cp -r /opt/nexus /opt/nexus_old 2>/dev/null || true
    msg_ok "Backed up Old Version"

    # Step 5: Download and deploy new version
    # CLEAN_INSTALL=1 removes old directory before extracting
    rm -rf /opt/nexus /opt/sonatype-work
    msg_info "Setting up Nexus ${LATEST_VERSION}"
    mkdir -p /opt/extract /opt/nexus /opt/sonatype-work
    wget https://cdn.download.sonatype.com/repository/downloads-prod-group/3/nexus-"${LATEST_VERSION}"-linux-x86_64.tar.gz -O /opt/extract/nexus.tar.gz
    tar -xvzf /opt/extract/nexus.tar.gz -C /opt/extract
    mv "/opt/extract/nexus-${LATEST_VERSION}/*" /opt/nexus
    mv /opt/extract/sonatype-work /opt/sonatype-work
    msg_ok "Set up Nexus ${LATEST_VERSION}"

# ==============================
# Run Post-Update Commands
# ==============================

msg_info "Setting up nexus user"
chown -R nexus:nexus /opt/nexus /opt/sonatype-work
/bin/echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc
msg_ok "Set up nexus user"

    # Step 8: Restart service with new version
    msg_info "Starting Service"
    systemctl start nexus
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

# =============================================
# MAIN EXECUTION - Container creation flow
# =============================================

start
build_container
description

# ============================================================================
# COMPLETION MESSAGE
# ============================================================================
msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8081${CL}"
echo -e "${INFO}${GN} The default credentials are:${CL}"
echo -e "${TAB}Username: ${BGN}admin${CL}"
password=$(cat /opt/sonatype-work/nexus3/admin.password 2>/dev/null || echo "unknown")
echo -e "${TAB}Password: ${BGN}${password}${CL}"
