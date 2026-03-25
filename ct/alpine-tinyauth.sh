#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021) | Co-Author: Stavros (steveiliop56)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/steveiliop56/tinyauth

APP="Alpine-Tinyauth"
var_tags="${var_tags:-alpine;auth}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  if [[ ! -d /opt/tinyauth ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating packages"
  $STD apk -U upgrade
  msg_ok "Updated packages"

  RELEASE=$(curl -s https://api.github.com/repos/steveiliop56/tinyauth/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
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
    curl -fsSL "https://github.com/steveiliop56/tinyauth/releases/download/v${RELEASE}/tinyauth-amd64" -o /opt/tinyauth/tinyauth
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
  exit 0
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
