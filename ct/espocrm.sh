#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Masked-Kunsiquat
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.espocrm.com/ | Github: https://github.com/espocrm/espocrm

APP="EspoCRM"
var_tags="${var_tags:-crm;business}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_admin_user="${var_admin_user:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/espocrm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "espocrm" "espocrm/espocrm"; then
    msg_info "Stopping Services"
    systemctl stop nginx cron php8.4-fpm
    msg_ok "Stopped Services"

    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="data custom client/custom" fetch_and_deploy_gh_release "espocrm" "espocrm/espocrm" "prebuild" "latest" "/opt/espocrm" "EspoCRM-*.zip"

    msg_info "Migrating EspoCRM"
    cd /opt/espocrm
    $STD php bin/command clear-cache
    if ! $STD php bin/command migrate; then
      rm -f ~/.espocrm
      chown -R www-data:www-data /opt/espocrm
      systemctl start php8.4-fpm
      systemctl start cron nginx
      msg_error "Migration failed; customizations may be incompatible. Check /opt/espocrm/data/logs, then run update again."
      exit 1
    fi
    chown -R www-data:www-data /opt/espocrm
    msg_ok "Migrated EspoCRM"

    msg_info "Starting Services"
    systemctl start php8.4-fpm
    systemctl start cron nginx
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
