#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/autobrr/netronome

APP="Netronome"
var_tags="${var_tags:-network;monitoring;speedtest}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/bin/netronome ]]; then
    msg_error "No Netronome Installation Found!"
    exit
  fi

  if check_for_gh_release "netronome" "autobrr/netronome" "" "" "v"; then
    msg_info "Stopping Netronome"
    systemctl stop netronome
    msg_ok "Stopped Netronome"

    fetch_and_deploy_gh_release "netronome" "autobrr/netronome" "binary" "latest" "" "netronome_*_linux_$(arch_resolve).deb" "v"

    msg_info "Starting Netronome"
    systemctl start netronome
    msg_ok "Started Netronome"
    msg_ok "Updated successfully!"
  fi

  if check_for_gh_release "librespeed-cli" "librespeed/speedtest-cli"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "librespeed-cli" "librespeed/speedtest-cli" "prebuild" "latest" "/opt/librespeed-cli" "librespeed-cli_*_linux_$(arch_resolve).tar.gz"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:7575${CL}"
echo -e "${INFO}${YW}Register your account right away: the registration page accepts only the first account, and until then anyone who reaches the port can claim it.${CL}"
