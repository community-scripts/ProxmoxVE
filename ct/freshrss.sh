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
var_unprivileged="${var_unprivileged:-1}"

WEB_UI_PORT=80
WEB_UI_PROTOCOL="http"

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

    msg_info "Backing up FreshRSS"
    mv /opt/freshrss /opt/freshrss-backup
    msg_ok "Backup Created"

    fetch_and_deploy_gh_release "freshrss" "FreshRSS/FreshRSS" "tarball"

    msg_info "Restoring data and configuration"
    if [[ -d /opt/freshrss-backup/data ]]; then
      cp -a /opt/freshrss-backup/data/. /opt/freshrss/data/
    fi
    if [[ -d /opt/freshrss-backup/extensions ]]; then
      cp -a /opt/freshrss-backup/extensions/. /opt/freshrss/extensions/
    fi
    msg_ok "Data Restored"

    msg_info "Setting permissions"
    chown -R www-data:www-data /opt/freshrss
    chmod -R g+rX /opt/freshrss
    chmod -R g+w /opt/freshrss/data/
    msg_ok "Permissions Set"

    msg_info "Starting Apache2"
    systemctl start apache2
    msg_ok "Started Apache2"

    msg_info "Cleaning up backup"
    rm -rf /opt/freshrss-backup
    msg_ok "Cleaned up backup"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
