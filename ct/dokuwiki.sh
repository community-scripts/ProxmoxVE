#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dokuwiki/dokuwiki

APP="DokuWiki"
var_tags="${var_tags:-wiki;documentation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/dokuwiki ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "dokuwiki" "dokuwiki/dokuwiki"; then
    msg_info "Stopping DokuWiki"
    systemctl stop nginx php8.4-fpm
    msg_ok "Stopped DokuWiki"

    fetch_and_deploy_gh_release "dokuwiki" "dokuwiki/dokuwiki" "prebuild" "latest" "/opt/dokuwiki" "dokuwiki-*.tgz"

    msg_info "Removing obsolete DokuWiki files"
    grep -E '^[[:alnum:]_][^[:space:]]*$' /opt/dokuwiki/data/deleted.files | grep -Fv '..' | sed 's|^|/opt/dokuwiki/|' | xargs -r -d '\n' rm -rf --
    rm -f /opt/dokuwiki/install.php /opt/dokuwiki/data/cache/messages.txt
    chown -R www-data:www-data /opt/dokuwiki
    msg_ok "Removed obsolete DokuWiki files"

    msg_info "Starting DokuWiki"
    systemctl start php8.4-fpm nginx
    msg_ok "Started DokuWiki"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}Admin login: /opt/dokuwiki_data/.env (inside the container)${CL}"
