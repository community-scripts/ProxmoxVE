#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tinyauthapp/tinyauth

APP="Tinyauth"
var_tags="${var_tags:-auth}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-256}"
  var_disk="${var_disk:-2}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-4}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /opt/tinyauth ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "tinyauth" "tinyauthapp/tinyauth"; then
    msg_info "Stopping Service"
    systemctl stop tinyauth
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "tinyauth" "tinyauthapp/tinyauth" "singlefile" "latest" "/opt/tinyauth" "tinyauth-$(arch_resolve)"

    msg_info "Starting Service"
    systemctl start tinyauth
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
}

update_alpine() {
  if [[ ! -d /opt/tinyauth ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating packages"
  $STD apk -U upgrade
  msg_ok "Updated packages"

  RELEASE=$(curl -s https://api.github.com/repos/tinyauthapp/tinyauth/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [ "${RELEASE}" != "$(cat ~/.tinyauth 2>/dev/null)" ] || [ ! -f ~/.tinyauth ]; then
    msg_info "Stopping Service"
    $STD service tinyauth stop
    msg_ok "Service Stopped"

    if [[ -f /opt/tinyauth/.env ]] && ! grep -q "^TINYAUTH_" /opt/tinyauth/.env; then
      msg_info "Migrating .env to v5 format"
      sed -i \
        -e 's/^DATABASE_PATH=/TINYAUTH_DATABASE_PATH=/' \
        -e 's/^USERS=/TINYAUTH_AUTH_USERS=/' \
        -e "s/^USERS='/TINYAUTH_AUTH_USERS='/" \
        -e 's/^APP_URL=/TINYAUTH_APPURL=/' \
        -e 's/^SECRET=/TINYAUTH_AUTH_SECRET=/' \
        -e 's/^PORT=/TINYAUTH_SERVER_PORT=/' \
        -e 's/^ADDRESS=/TINYAUTH_SERVER_ADDRESS=/' \
        /opt/tinyauth/.env
      msg_ok "Migrated .env to v5 format"
    fi

    msg_info "Updating Tinyauth"
    rm -f /opt/tinyauth/tinyauth
    curl -fsSL "https://github.com/tinyauthapp/tinyauth/releases/download/v${RELEASE}/tinyauth-$(arch_resolve)" -o /opt/tinyauth/tinyauth
    chmod +x /opt/tinyauth/tinyauth
    echo "${RELEASE}" >~/.tinyauth
    msg_ok "Updated Tinyauth"

    msg_info "Restarting Tinyauth"
    $STD service tinyauth start
    msg_ok "Restarted Tinyauth"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
