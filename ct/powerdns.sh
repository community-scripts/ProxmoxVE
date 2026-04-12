#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.powerdns.com/

APP="PowerDNS"
var_tags="${var_tags:-dns}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/poweradmin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating PowerDNS"
  $STD apt update
  $STD apt install -y --only-upgrade pdns-server pdns-backend-sqlite3
  msg_ok "Updated PowerDNS"

  if check_for_gh_release "poweradmin" "poweradmin/poweradmin"; then
    msg_info "Backing up Configuration"
    cp /opt/poweradmin/config/settings.php /opt/poweradmin_settings.php.bak
    cp /opt/poweradmin/powerdns.db /opt/poweradmin_powerdns.db.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "poweradmin" "poweradmin/poweradmin" "tarball"

    msg_info "Updating Poweradmin"
    cp /opt/poweradmin_settings.php.bak /opt/poweradmin/config/settings.php
    cp /opt/poweradmin_powerdns.db.bak /opt/poweradmin/powerdns.db
    rm -rf /opt/poweradmin/install
    rm -f /opt/poweradmin_settings.php.bak /opt/poweradmin_powerdns.db.bak
    chown -R www-data:pdns /opt/poweradmin
    chmod 775 /opt/poweradmin
    chown pdns:pdns /opt/poweradmin/powerdns.db
    chmod 664 /opt/poweradmin/powerdns.db
    msg_ok "Updated Poweradmin"

    msg_info "Restarting Services"
    systemctl restart pdns apache2
    msg_ok "Restarted Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
