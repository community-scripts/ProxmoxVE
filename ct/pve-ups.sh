#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ffind-dev/pve-ups

APP="PVE-UPS"
var_tags="${var_tags:-proxmox;ups;monitoring;network}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/pve-usv ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pve-usv" "ffind-dev/pve-ups"; then
    msg_info "Stopping Services"
    systemctl stop pve-usv pve-usv-agent.path pve-usv-agent.timer
    msg_ok "Stopped Services"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pve-usv" "ffind-dev/pve-ups" "tarball"

    msg_info "Updating Application"
    cd /opt/pve-usv
    $STD uv venv --clear --seed venv
    $STD uv pip install --python venv/bin/python .
    chown -R pveusv:pveusv /opt/pve-usv
    chmod 0755 deploy/pve-usv-agent.sh
    install -m 0644 deploy/pve-usv.service /etc/systemd/system/pve-usv.service
    install -m 0644 deploy/pve-usv-agent.service /etc/systemd/system/pve-usv-agent.service
    install -m 0644 deploy/pve-usv-agent.path /etc/systemd/system/pve-usv-agent.path
    install -m 0644 deploy/pve-usv-agent.timer /etc/systemd/system/pve-usv-agent.timer
    systemctl daemon-reload
    msg_ok "Updated Application"

    msg_info "Starting Services"
    systemctl start pve-usv pve-usv-agent.path pve-usv-agent.timer
    msg_ok "Started Services"
    msg_ok "Updated ${APP}"
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
