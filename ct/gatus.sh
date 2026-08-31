#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TwiN/gatus

APP="gatus"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-2048}"
  var_disk="${var_disk:-3}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-2048}"
  var_disk="${var_disk:-4}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /opt/gatus ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "gatus" "TwiN/gatus"; then
    msg_info "Stopping Service"
    systemctl stop gatus
    msg_ok "Stopped Service"

    mv /opt/gatus/config/config.yaml /opt
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gatus" "TwiN/gatus" "tarball"
    GO_VERSION="$(grep -m1 '^go ' /opt/gatus/go.mod | awk '{print $2}')" setup_go

    msg_info "Updating Gatus"
    cd /opt/gatus
    $STD go mod tidy
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
    setcap CAP_NET_RAW+ep gatus
    mv /opt/config.yaml config
    msg_ok "Updated Gatus"

    msg_info "Starting Service"
    systemctl start gatus
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
}

update_alpine() {
  if [[ ! -d /opt/gatus ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "gatus" "TwiN/gatus"; then
    msg_info "Updating ${APP}"
    $STD apk -U upgrade
    $STD service gatus stop
    mv /opt/gatus/config/config.yaml /opt
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gatus" "TwiN/gatus" "tarball"
    cd /opt/gatus
    $STD go get golang.org/x/net@v0.55.0
    $STD go mod tidy
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
    setcap CAP_NET_RAW+ep gatus
    mv /opt/config.yaml config
    $STD service gatus start
    msg_ok "Updated successfully!"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
