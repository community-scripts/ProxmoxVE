#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/scanopy/scanopy

APP="Scanopy"
var_tags="${var_tags:-analytics}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/scanopy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "scanopy-server" "scanopy/scanopy"; then
    msg_info "Stopping services"
    systemctl stop scanopy-server
    [[ -f /etc/systemd/system/scanopy-daemon.service ]] && systemctl stop scanopy-daemon
    msg_ok "Stopped services"

    if ! grep -q "PUBLIC_URL" /opt/scanopy/.env; then
      sed -i "\|_PATH=|a\\SCANOPY_PUBLIC_URL=http://${LOCAL_IP}:60072" /opt/scanopy/.env
    fi
    sed -i 's|_TARGET=.*$|_URL=http://127.0.0.1:60072|' /opt/scanopy/.env
    sed -i '/^SCANOPY_WEB_EXTERNAL_PATH=/d' /opt/scanopy/.env
    sed -i 's|^WorkingDirectory=/opt/scanopy/backend$|WorkingDirectory=/opt/scanopy|' /etc/systemd/system/scanopy-server.service
    systemctl daemon-reload

    cp -f /usr/bin/scanopy-server /usr/bin/scanopy-server.bak 2>/dev/null || true

    fetch_and_deploy_gh_release "scanopy-server" "scanopy/scanopy" "singlefile" "latest" "/usr/bin" "scanopy-server-linux-$(arch_resolve)"

    rm -rf /opt/scanopy/backend /opt/scanopy/ui

    if [[ -f /etc/systemd/system/scanopy-daemon.service ]]; then
      fetch_and_deploy_gh_release "Scanopy Daemon" "scanopy/scanopy" "singlefile" "latest" "/usr/local/bin" "scanopy-daemon-linux-$(arch_resolve)"
      mv "/usr/local/bin/Scanopy Daemon" /usr/local/bin/scanopy-daemon
      rm -f /usr/bin/scanopy-daemon ~/configure_daemon.sh
      sed -i -e 's|usr/bin|usr/local/bin|' \
        -e 's/push/daemon_poll/' \
        -e 's/pull/server_poll/' /etc/systemd/system/scanopy-daemon.service
      systemctl daemon-reload
      msg_ok "Updated Scanopy Daemon"
    fi

    msg_info "Starting services"
    systemctl start scanopy-server
    healthy=0
    for _ in {1..30}; do
      if curl -fsS -o /dev/null http://127.0.0.1:60072/api/health 2>/dev/null; then
        healthy=1
        break
      fi
      sleep 2
    done
    if [[ "$healthy" -ne 1 ]]; then
      systemctl stop scanopy-server
      [[ -f /usr/bin/scanopy-server.bak ]] && mv -f /usr/bin/scanopy-server.bak /usr/bin/scanopy-server
      systemctl start scanopy-server
      msg_error "New server did not answer /api/health, restored the previous binary"
      exit 1
    fi
    rm -f /usr/bin/scanopy-server.bak
    [[ -f /etc/systemd/system/scanopy-daemon.service ]] && systemctl start scanopy-daemon
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
echo -e "${GATEWAY}${BGN}http://${IP}:60072${CL}"
echo -e "${INFO}${YW} Then create your account, and create a daemon in the UI.${CL}"
