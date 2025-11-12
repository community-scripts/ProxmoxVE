#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wallosapp.com/

APP="Wallos"
var_tags="${var_tags:-finance}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/wallos ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "wallos" "ellite/Wallos"; then
    msg_info "Creating backup"
    mkdir -p /opt/logos
    mv /opt/wallos/db/wallos.db /opt/wallos.db
    mv /opt/wallos/images/uploads/logos /opt/logos/
    msg_ok "Backup created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wallos" "ellite/Wallos" "tarball"

    msg_info "Configuring Wallos"
    rm -rf /opt/wallos/db/wallos.empty.db
    mv /opt/wallos.db /opt/wallos/db/wallos.db
    mv /opt/logos/* /opt/wallos/images/uploads/logos
    if ! grep -q "storetotalyearlycost.php" /opt/wallos.cron; then
      echo "30 1 * * 1 php /opt/wallos/endpoints/cronjobs/storetotalyearlycost.php >> /var/log/cron/storetotalyearlycost.log 2>&1" >>/opt/wallos.cron
    fi
    chown -R www-data:www-data /opt/wallos
    chmod -R 755 /opt/wallos
    mkdir -p /var/log/cron
    $STD curl http://localhost/endpoints/db/migrate.php
    msg_ok "Configured Wallos"

    msg_info "Reload Apache2"
    systemctl reload apache2
    msg_ok "Apache2 Reloaded"
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
