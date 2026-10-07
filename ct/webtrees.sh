#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: sudofly
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://webtrees.net/

APP="Webtrees"
var_tags="${var_tags:-genealogy;cms}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/webtrees ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! grep -q "@private" /etc/caddy/Caddyfile; then
    msg_info "Blocking direct access to webtrees data"
    cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak
    sed -i '\|root \* /opt/webtrees|a\    @private path /app/* /data/* /modules_v4/* /resources/* /vendor/* /.*\n    respond @private 403' /etc/caddy/Caddyfile
    if grep -q "@private" /etc/caddy/Caddyfile && caddy validate --config /etc/caddy/Caddyfile &>/dev/null; then
      rm -f /etc/caddy/Caddyfile.bak
      systemctl reload-or-restart caddy
      msg_ok "Blocked direct access to webtrees data"
    else
      mv /etc/caddy/Caddyfile.bak /etc/caddy/Caddyfile
      msg_warn "Could not patch /etc/caddy/Caddyfile - deny /data/ there by hand"
    fi
  fi

  if check_for_gh_release "webtrees" "fisharebest/webtrees"; then
    msg_info "Stopping Service"
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
    systemctl stop caddy php${PHP_VER}-fpm
    msg_ok "Stopped Service"

    create_backup /opt/webtrees/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "webtrees" "fisharebest/webtrees" "prebuild" "latest" "/opt/webtrees" "webtrees-*.zip"

    restore_backup
    chown -R www-data:www-data /opt/webtrees

    msg_info "Starting Service"
    systemctl start caddy php${PHP_VER}-fpm
    msg_ok "Started Service"
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
