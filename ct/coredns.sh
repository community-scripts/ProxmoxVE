#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/coredns/coredns

APP="CoreDNS"
var_tags="${var_tags:-dns;network}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-1}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/local/bin/coredns ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "coredns" "coredns/coredns"; then
    msg_info "Stopping Service"
    systemctl stop coredns
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "coredns" "coredns/coredns" "prebuild" "latest" "/usr/local/bin" \
      "coredns_*_linux_$(dpkg --print-architecture).tgz"
    chmod +x /usr/local/bin/coredns

    msg_info "Starting Service"
    systemctl start coredns
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} CoreDNS is listening on port 53 (DNS)${CL}"
echo -e "${TAB}${GATEWAY}${BGN}dns://${IP}${CL}"
