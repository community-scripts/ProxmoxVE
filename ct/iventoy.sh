#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.iventoy.com/en/index.html

APP="iVentoy"
var_tags="${var_tags:-pxe-tool}"
var_disk="${var_disk:-2}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/iventoy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "iventoy" "ventoy/PXE"; then
    msg_info "Stopping iVentoy"
    systemctl stop iventoy
    msg_ok "Stopped iVentoy"

    # Only preserve user state; data/iventoy.dat must match the new executable.
    create_backup /opt/iventoy/data/config.dat /opt/iventoy/iso /opt/iventoy/user
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "iventoy" "ventoy/PXE" "prebuild" "latest" "/opt/iventoy" "iventoy-*-linux-$(arch_resolve x86_64-free arm64-trial).tar.gz"
    restore_backup

    # Migrate existing services that invoke the Bash launcher with sh.
    mkdir -p /etc/systemd/system/iventoy.service.d
    cat <<EOF >/etc/systemd/system/iventoy.service.d/launcher.conf
[Service]
ExecStart=
ExecStart=/bin/bash /opt/iventoy/iventoy.sh -R start
ExecStop=
ExecStop=/bin/bash /opt/iventoy/iventoy.sh stop
PIDFile=/run/iventoy.pid
RestartSec=5
EOF
    systemctl daemon-reload

    msg_info "Starting iVentoy"
    systemctl reset-failed iventoy
    systemctl start iventoy
    # The launcher can return success before the daemon fails initialization.
    local i ready=0
    for ((i = 0; i < 90; i++)); do
      if systemctl is-active --quiet iventoy && curl -fsS --max-time 2 "${IVENTOY_HEALTH_URL:-http://127.0.0.1:26000/}" >/dev/null 2>&1; then
        ready=1
        break
      fi
      sleep 2
    done
    if [[ "$ready" -ne 1 ]]; then
      msg_error "iVentoy did not become ready; check journalctl -u iventoy and /opt/iventoy/log/log.txt"
      exit 1
    fi
    msg_ok "Started iVentoy"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:26000${CL}"
