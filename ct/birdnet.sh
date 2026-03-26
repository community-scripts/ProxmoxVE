#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tphakala/birdnet-go

APP="BirdNET"
var_tags="${var_tags:-monitoring;ai;nature}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-12}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-no}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/local/bin/birdnet-go ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "birdnet" "tphakala/birdnet-go"; then
    msg_info "Stopping Service"
    systemctl stop birdnet
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "birdnet" "tphakala/birdnet-go" "prebuild" "latest" "/opt/birdnet" "birdnet-go-linux-amd64.tar.gz"

    msg_info "Deploying Binary"
    cp /opt/birdnet/birdnet-go /usr/local/bin/birdnet-go
    chmod +x /usr/local/bin/birdnet-go
    cp -r /opt/birdnet/libtensorflowlite_c.so /usr/local/lib/ || true
    ldconfig
    msg_ok "Deployed Binary"

    msg_info "Starting Service"
    systemctl start birdnet
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
