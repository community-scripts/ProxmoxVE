#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/valhalla/valhalla

APP="Valhalla"
var_tags="${var_tags:-mapping;routing}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-24}"
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

  if [[ ! -f /etc/systemd/system/valhalla.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "prime_server" "kevinkreiser/prime_server"; then
    RELEASE="$CHECK_UPDATE_RELEASE"

    msg_info "Stopping Service"
    systemctl stop valhalla
    msg_ok "Stopped Service"

    msg_info "Building prime_server ${RELEASE} (Patience)"
    rm -rf /tmp/prime_server
    git clone --recurse-submodules --depth 1 --branch "$RELEASE" https://github.com/kevinkreiser/prime_server /tmp/prime_server
    cd /tmp/prime_server
    $STD ./autogen.sh
    $STD ./configure
    $STD make -j"$(nproc)"
    $STD make install
    cd /
    rm -rf /tmp/prime_server
    ldconfig
    echo "${RELEASE#v}" >"$HOME/.prime_server"
    msg_ok "Built prime_server ${RELEASE}"

    msg_info "Starting Service"
    systemctl start valhalla
    msg_ok "Started Service"
  fi

  if check_for_gh_release "valhalla" "valhalla/valhalla"; then
    RELEASE="$CHECK_UPDATE_RELEASE"

    msg_info "Stopping Service"
    systemctl stop valhalla
    msg_ok "Stopped Service"

    msg_info "Fetching Valhalla ${RELEASE} (Patience)"
    rm -rf /opt/valhalla
    git clone --recurse-submodules --depth 1 --branch "$RELEASE" https://github.com/valhalla/valhalla.git /opt/valhalla
    msg_ok "Fetched Valhalla ${RELEASE}"

    msg_info "Compiling Valhalla ${RELEASE} (this takes 20-45+ minutes, be patient)"
    MEM_MB=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
    BUILD_JOBS=$((MEM_MB / 2000))
    [[ $BUILD_JOBS -lt 1 ]] && BUILD_JOBS=1
    [[ $BUILD_JOBS -gt $(nproc) ]] && BUILD_JOBS=$(nproc)
    cd /opt/valhalla
    $STD cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_TESTS=OFF -DENABLE_SINGLE_FILES_WERROR=OFF
    $STD cmake --build build -- -j"$BUILD_JOBS"
    $STD cmake --install build
    ldconfig
    echo "${RELEASE#v}" >"$HOME/.valhalla"
    msg_ok "Compiled Valhalla ${RELEASE}"

    msg_info "Starting Service"
    systemctl start valhalla
    msg_ok "Started Service"
  fi

  msg_ok "Updated Successfully!\n"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8002/status${CL}"
echo -e "${INFO}${YW}No routing tiles are built yet. Build them for your region with:${CL}"
echo -e "${TAB}${BGN}/opt/valhalla_data/build-tiles.sh https://download.geofabrik.de/<continent>/<region>-latest.osm.pbf${CL}"
