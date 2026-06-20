#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FreshRSS/FreshRSS

APP="FreshRSS"
var_tags="${var_tags:-RSS}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/freshrss ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [ ! -x /opt/freshrss/cli/sensitive-log.sh ]; then
    msg_info "Fixing wrong permissions"
    chmod +x /opt/freshrss/cli/sensitive-log.sh
    systemctl restart apache2
    msg_ok "Fixed wrong permissions"
  fi

  if check_for_gh_release "freshrss" "FreshRSS/FreshRSS"; then
    msg_info "Stopping Apache2"
    systemctl stop apache2
    msg_ok "Stopped Apache2"

    create_backup /opt/freshrss /opt/freshrss/data /opt/freshrss/extensions

    fetch_and_deploy_gh_release "freshrss" "FreshRSS/FreshRSS" "tarball"
    restore_backup


    msg_info "Setting permissions"
    chown -R www-data:www-data /opt/freshrss
    chmod -R g+rX /opt/freshrss
    chmod -R g+w /opt/freshrss/data/
    msg_ok "Permissions Set"

    msg_info "Starting Apache2"
    systemctl start apache2
    msg_ok "Started Apache2"

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
