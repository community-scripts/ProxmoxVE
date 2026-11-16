#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nicolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tvheadend.org/ | Github: https://github.com/tvheadend/tvheadend

APP="Tvheadend"
var_tags="${var_tags:-media;pvr;tv;dvr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

export var_admin_user="${var_admin_user:-admin}"
export var_admin_pass="${var_admin_pass:-$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /var/lib/tvheadend ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating Tvheadend"
  $STD apt update
  $STD apt install -y tvheadend
  msg_ok "Updated Tvheadend"

  msg_info "Restarting Service"
  systemctl restart tvheadend
  msg_ok "Restarted Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:9981${CL}"
echo -e "${INFO}${YW}Admin Username: ${var_admin_user}${CL}"
echo -e "${INFO}${YW}Admin Password: ${var_admin_pass}${CL}"
