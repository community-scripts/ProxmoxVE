#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: 007hacky007
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.squid-cache.org/

APP="Squid"
var_tags="${var_tags:-proxy}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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
  if [[ ! -f /etc/squid/squid.conf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating Squid"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated Squid"

  msg_info "Validating Squid Configuration"
  $STD squid -k parse
  msg_ok "Validated Squid Configuration"

  msg_info "Restarting Squid"
  systemctl restart squid
  msg_ok "Restarted Squid"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Proxy endpoint:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:3128${CL}"
echo -e "${INFO}${YW} Add a proxy user inside the container with:${CL}"
echo -e "${TAB}${BGN}htpasswd /etc/squid/passwords <username>${CL}"
