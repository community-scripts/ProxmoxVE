#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.projectsend.org/ | Github: https://github.com/projectsend/projectsend

APP="ProjectSend"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /opt/projectsend ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ -f /opt/projectsend/includes/sys.config.php ]]; then
    msg_error "This container runs ProjectSend Legacy (pre-2.0)."
    msg_error "2.0 is a new application, not an update - there is no in-place upgrade."
    msg_error "Set up a fresh ProjectSend container and use projectsend/v1-migration-tool to bring your data across."
    exit
  fi

  if check_for_gh_release "projectsend" "projectsend/projectsend"; then
    msg_info "Stopping Services"
    systemctl stop nginx projectsend-worker
    msg_ok "Stopped Services"

    create_backup /opt/projectsend/.env /opt/projectsend/storage/app/files

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "projectsend" "projectsend/projectsend" "prebuild" "latest" "/opt/projectsend"

    restore_backup

    msg_info "Updating ProjectSend"
    cd /opt/projectsend
    chown -R www-data:www-data /opt/projectsend
    chmod -R 775 /opt/projectsend/storage /opt/projectsend/bootstrap/cache
    $STD sudo -u www-data php artisan migrate --force
    $STD sudo -u www-data php artisan projectsend:ensure-roles
    $STD sudo -u www-data php artisan optimize:clear
    msg_ok "Updated ProjectSend"

    msg_info "Starting Services"
    systemctl start nginx projectsend-worker
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}Admin credentials saved to ~/projectsend.creds${CL}"
