#!/usr/bin/env bash
# Engine comes from community-scripts/core; this repo only ships the scripts.
# Local checkout wins (COMMUNITY_SCRIPTS_CORE_DIR, else a sibling ../core), so a
# fork/branch of core can be tested without touching this file.
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: mews-se
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dietpi.com/

APP="DietPi"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /boot/dietpi/.version ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating DietPi LXC"
  $STD /boot/dietpi/dietpi-update 1
  msg_ok "Updated DietPi LXC"
  exit
}

start
build_container
description

msg_info "Restarting ${APP} for DietPi's first boot"
if command -v pct &>/dev/null; then
  pct reboot "$CTID"
else
  incus restart "$CTID"
fi
msg_ok "Restarted ${APP}"

msg_ok "Completed successfully!"
msg_custom "🚀" "${GN}" "${APP} setup has been successfully initialized!"
echo -e "${INFO}${YW} DietPi's first run setup starts at the next console login.${CL}"
