#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman & vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/Pulse

APP="Pulse"
var_tags="${var_tags:-monitoring,proxmox}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/pulse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [[ ! -f ~/.pulse ]]; then
    msg_error "Old Installation Found! Please recreate the container due big changes in the software."
    exit 1
  fi
  if check_for_gh_release "pulse" "rcourtman/Pulse"; then
    SERVICE_PATH="/etc/systemd/system"
    msg_info "Stopping Services"
    systemctl stop pulse*.service
    msg_ok "Stopped Services"

    if [[ -f /opt/pulse/pulse ]]; then
      rm -f /opt/pulse/pulse
    fi

    fetch_and_deploy_gh_release "pulse" "rcourtman/Pulse" "prebuild" "latest" "/opt/pulse" "*-linux-amd64.tar.gz"
    chown -R pulse:pulse /etc/pulse /opt/pulse
    if [[ -f "$SERVICE_PATH"/pulse.service ]]; then
      mv "$SERVICE_PATH"/pulse.service "$SERVICE_PATH"/pulse-backend.service
    fi
    sed -i -e 's|pulse/pulse|pulse/bin/pulse|' \
      -e 's/^Environment="API.*$//' "$SERVICE_PATH"/pulse-backend.service
    systemctl daemon-reload
    if grep -q 'pulse-home:/bin/bash' /etc/passwd; then
      usermod -s /usr/sbin/nologin pulse
    fi

    msg_info "Starting Services"
    systemctl start pulse-backend
    msg_ok "Started Services"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7655${CL}"
