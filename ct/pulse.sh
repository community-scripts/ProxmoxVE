#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: rcourtman & vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/Pulse

APP="Pulse"
var_tags="${var_tags:-monitoring;proxmox}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /opt/pulse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pulse" "rcourtman/Pulse"; then
    SERVICE_PATH="/etc/systemd/system"
    msg_info "Stopping Services"
    systemctl stop pulse*.service
    msg_ok "Stopped Services"

    if ! CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pulse" "rcourtman/Pulse" "prebuild" "latest" "/opt/pulse" "pulse-v*-linux-$(arch_resolve).tar.gz"; then
      msg_error "Download or deployment failed - check network connectivity and GitHub API availability"
      if systemctl start pulse 2>/dev/null || systemctl start pulse-backend 2>/dev/null; then
        msg_ok "Restarted the previously installed ${APP}"
      else
        msg_error "${APP} could not be restarted - reinstall it or restore the container from a backup"
      fi
      exit 250
    fi
    ln -sf /opt/pulse/bin/pulse /usr/local/bin/pulse
    mkdir -p /etc/pulse
    chown pulse:pulse /etc/pulse
    chown -R pulse:pulse /opt/pulse
    chmod 700 /etc/pulse
    UNIT_WAS_ENABLED=0
    if [[ -f "$SERVICE_PATH"/pulse-backend.service ]]; then
      if [[ $(systemctl is-enabled pulse-backend) == enabled ]]; then
        UNIT_WAS_ENABLED=1
      fi
      systemctl disable -q pulse-backend.service 2>/dev/null || true
      mv "$SERVICE_PATH"/pulse-backend.service "$SERVICE_PATH"/pulse.service
    fi
    sed -i -e 's|pulse/pulse|pulse/bin/pulse|' \
      -e 's/^Environment="API.*$//' "$SERVICE_PATH"/pulse.service
    systemctl daemon-reload
    if [[ "$UNIT_WAS_ENABLED" == "1" ]]; then
      systemctl enable -q pulse
    fi
    if grep -q 'pulse-home:/bin/bash' /etc/passwd; then
      usermod -s /usr/sbin/nologin pulse
    fi

    msg_info "Starting Services"
    systemctl start pulse
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:7655${CL}"
