#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PatchMon/PatchMon

APP="PatchMon"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d "/opt/patchmon" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE="v2.0.2"
  if check_for_gh_release "PatchMon" "PatchMon/PatchMon" "${RELEASE}"; then
    msg_info "Stopping Service"
    systemctl stop patchmon-server
    msg_ok "Stopped Service"

    if [[ -d /opt/patchmon/backend ]]; then
      msg_info "Legacy install detected - creating full backup, please wait..."
      $STD tar czf ~/patchmon_legacy.tar.gz /opt/patchmon
      cp /opt/patchmon/backend/.env /opt/legacy.env
      msg_ok "Full backup saved in /root"
      msg_info "Starting migration to PatchMon v2.x.x"
      systemctl disable -q --now nginx
      $STD npm cache clean --force
      $STD apt autoremove --purge -y {nginx,nodejs}
      if [[ -f /etc/apt/sources.list.d/nodesource.sources ]]; then
        cp /etc/apt/sources.list.d/nodesource.sources /etc/apt/sources.list.d/nodesource.sources.bak
        rm -f /etc/apt/sources.list.d/nodesource.sources
      elif [[ -f /etc/apt/sources.list.d/nodesource.list ]]; then
        cp /etc/apt/sources.list.d/nodesource.list /etc/apt/sources.list.d/nodesource.list.bak
        rm -f /etc/apt/sources.list.d/nodesource.list
      fi
      rm -rf /opt/patchmon
      mkdir -p /opt/patchmon/agents
      cp /opt/legacy.env /opt/patchmon/.env
      sed -i -e 's/^PORT=.*/PORT=3000/' \
        -e 's/^NODE_/APP_/' \
        -e '/^SERVER_*/d' \
        -e '/^# API*/,+2d' /opt/patchmon/.env
      {
        echo ""
        echo "SESSION_SECRET=$(openssl rand -hex 64)"
        echo "AI_ENCRYPTION_KEY=$(openssl rand -hex 64)"
        echo "AGENT_BINARIES_DIR=/opt/patchmon/agents"
      } >>/opt/patchmon/.env
      sed -i -e '\|Directory|s|/backend||' \
        -e 's|^ExecStart=.*|ExecStart=/opt/patchmon/patchmon-server|' \
        -e 's|^Environment=NODE_.*|EnvironmentFile=/opt/patchmon/.env|' \
        /etc/systemd/system/patchmon-server.service
      systemctl daemon-reload
      rm /opt/legacy.env
      msg_ok "Migration complete!"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "PatchMon" "PatchMon/PatchMon" "singlefile" "${RELEASE}" "/opt/patchmon" "patchmon-server-linux-amd64"
    mv /opt/patchmon/PatchMon /opt/patchmon/patchmon-server

    msg_info "Fetching PatchMon agent binaries"
    [[ ! -d /opt/patchmon/agents ]] && mkdir -p /opt/patchmon/agents
    FILE_URL="https://github.com/PatchMon/PatchMon/releases/download/${RELEASE}/patchmon-agent-"
    AGENT_NAME=(
      "linux-amd64"
      "linux-arm64"
      "linux-arm"
      "linux-386"
      "freebsd-amd64"
      "freebsd-arm64"
      "freebsd-arm"
      "freebsd-386"
      "windows-amd64.exe"
      "windows-arm64.exe"
    )
    for arch in "${AGENT_NAME[@]}"; do
      curl_with_retry "${FILE_URL}${arch}" "/opt/patchmon/agents/patchmon-agent-${arch}"
      [[ "${arch}" != *.exe ]] && chmod 755 "/opt/patchmon/agents/patchmon-agent-${arch}"
    done
    msg_ok "Fetched PatchMon agent binaries"

    msg_info "Starting Service"
    systemctl start patchmon-server
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
