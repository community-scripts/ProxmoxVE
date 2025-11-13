#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Hosteroid/domain-monitor

APP="Domain-Monitor"
var_tags="${var_tags:-proxy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -d /opt/domain-monitor ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! grep -Fq "root /usr/bin/php /opt/domain-monitor/cron/check_domains.php" /etc/crontab; then
    echo "0 0 * * * root /usr/bin/php /opt/domain-monitor/cron/check_domains.php" >>/etc/crontab
  fi

  if check_for_gh_release "domain-monitor" "Hosteroid/domain-monitor"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_info "Service stopped"

    msg_info "Creating backup"
    mv /opt/domain-monitor/.env /opt
    msg_ok "Created backup"

    setup_composer
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "domain-monitor" "Hosteroid/domain-monitor" "prebuild" "latest" "/opt/domain-monitor" "domain-monitor-v*.zip"

    msg_info "Updating Domain Monitor"
    cd /opt/domain-monitor
    $STD composer install
    msg_ok "Updated Domain Monitor"

    msg_info "Restoring backup"
    mv /opt/.env /opt/domain-monitor
    msg_ok "Restored backup"

    msg_info "Restarting Services"
    systemctl reload apache2
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
