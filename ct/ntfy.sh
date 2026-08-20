#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ntfy.sh/

APP="ntfy"
var_tags="${var_tags:-notification}"
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
  var_disk="${var_disk:-2}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /etc/ntfy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [ -f /etc/apt/keyrings/archive.heckel.io.gpg ]; then
    msg_info "Correcting old Ntfy Repository"
    rm -f /etc/apt/keyrings/archive.heckel.io.gpg
    rm -f /etc/apt/sources.list.d/archive.heckel.io.list
    rm -f /etc/apt/sources.list.d/archive.heckel.io.list.bak
    rm -f /etc/apt/sources.list.d/archive.heckel.io.sources
    setup_deb822_repo \
      "ntfy" \
      "https://archive.ntfy.sh/apt/keyring.gpg" \
      "https://archive.ntfy.sh/apt/" \
      "stable"
    msg_ok "Corrected old Ntfy Repository"
  fi

  msg_info "Updating ntfy"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated ntfy"
  msg_ok "Updated successfully!"
}

update_alpine() {
  if [[ ! -d /etc/ntfy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ntfy LXC"
  $STD apk -U upgrade
  setcap 'cap_net_bind_service=+ep' /usr/bin/ntfy
  msg_ok "Updated ntfy LXC"

  msg_info "Restarting ntfy"
  rc-service ntfy restart
  msg_ok "Restarted ntfy"
  msg_ok "Updated successfully!"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
