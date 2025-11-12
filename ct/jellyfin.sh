#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jellyfin.org/

APP="Jellyfin"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-16}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /usr/lib/jellyfin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! grep -qEi 'ubuntu' /etc/os-release; then
    msg_info "Updating Intel Dependencies"
    rm -f ~/.intel-* || true
    fetch_and_deploy_gh_release "intel-igc-core-2" "intel/intel-graphics-compiler" "binary" "latest" "" "intel-igc-core-2_*_amd64.deb"
    fetch_and_deploy_gh_release "intel-igc-opencl-2" "intel/intel-graphics-compiler" "binary" "latest" "" "intel-igc-opencl-2_*_amd64.deb"
    fetch_and_deploy_gh_release "intel-libgdgmm12" "intel/compute-runtime" "binary" "latest" "" "libigdgmm12_*_amd64.deb"
    fetch_and_deploy_gh_release "intel-opencl-icd" "intel/compute-runtime" "binary" "latest" "" "intel-opencl-icd_*_amd64.deb"
    msg_ok "Updated Intel Dependencies"
  fi

  msg_info "Updating Jellyfin"
  if ! dpkg -s libjemalloc2 >/dev/null 2>&1; then
    $STD apt install -y libjemalloc2
  fi
  if [[ ! -f /usr/lib/libjemalloc.so ]]; then
    ln -sf /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so
  fi
  $STD apt update
  $STD apt -y upgrade
  $STD apt -y --with-new-pkgs upgrade jellyfin jellyfin-server
  msg_ok "Updated Jellyfin"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8096${CL}"
