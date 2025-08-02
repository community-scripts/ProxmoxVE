#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Arian Nasr (arian-nasr)
# Updated by: Javier Pastor (vsc55) 
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.freepbx.org/
#
# Changelog:
# ----------------------------------------------------------
# 27/07/2025 by Javier Pastor (vsc55)
# - Added option to remove commercial modules
# - Added option to update system and modules
# - Added verbose mode for better debugging or to see what's going on behind the scenes
#
# Initial Script by Arian Nasr (arian-nasr)

APP="FreePBX"
var_tags="pbx;voip;telephony"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

run_bin() {
  local code=0

  if [[ "$VERBOSE" == "yes" ]]; then
    print_msg ok "Running command [$*]...\n"
    "$@"
    code=$?
    if [[ $code -ne 0 ]]; then
      print_msg error "Command failed [$*] with exit code $code\n"
    fi
  else
    $STD "$@"
    code=$?
  fi
  return $code
}

print_msg() {
  local type="$1"
  local txt_normal="${2:-}"
  local txt_verbose="${3:-}"

  local func="msg_$type"

  if [[ "$VERBOSE" == "yes" ]]; then
    if [[ -n "$txt_verbose" ]]; then
      $func "$txt_verbose"
    else
      $func "$txt_normal\n"
    fi
  else
    $func "$txt_normal"
  fi
}

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -f /lib/systemd/system/freepbx.service ]]; then
        print_msg error "No ${APP} Installation Found!"
        exit
    fi

    print_msg info "Updating $APP LXC"
    run_bin apt-get update
    run_bin apt-get -y upgrade
    print_msg ok "Updated $APP LXC"

    print_msg info "Updating $APP Modules"
    run_bin fwconsole ma updateall
    run_bin fwconsole reload
    print_msg ok "Updated $APP Modules"

    exit
}

start

if whiptail --title "Comercial Modules?" --yesno "Remove Commercial modules?" --defaultno 10 50; then
  export ONLY_OPENSOURCE="yes"
else
  export ONLY_OPENSOURCE="no"
fi

build_container
description

print_msg ok "Completed Successfully!"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
