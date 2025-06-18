#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/arunavo4/gitea-mirror

APP="gitea-mirror"
var_tags="${var_tags:-mirror;gitea}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /opt/gitea-mirror ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/arunavo4/gitea-mirror/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat ~/.${APP} 2>/dev/null || cat /opt/${APP}_version.txt 2>/dev/null)" ]]; then

    msg_info "Stopping Services"
    systemctl stop gitea-mirror
    msg_ok "Services Stopped"

    msg_info "Backup Data"
    mkdir -p /opt/gitea-mirror-backup/data
    cp /opt/gitea-mirror/data/* /opt/gitea-mirror-backup/data/
    msg_ok "Backup Data"

    msg_info "Installing Bun"
    export BUN_INSTALL=/opt/bun
    curl -fsSL https://bun.sh/install | $STD bash
    ln -sf /opt/bun/bin/bun /usr/local/bin/bun
    ln -sf /opt/bun/bin/bun /usr/local/bin/bunx
    msg_ok "Installed Bun"

    rm -rf /opt/gitea-mirror
    fetch_and_deploy_gh_release "gitea-mirror" "arunavo4/gitea-mirror"

    msg_info "Updating and rebuilding ${APP} to v${RELEASE}"
    cd /opt/gitea-mirror
    $STD bun run setup
    $STD bun run build
    APP_VERSION=$(grep -o '"version": *"[^"]*"' package.json | cut -d'"' -f4)
    sudo sed -i.bak "s|^Environment=npm_package_version=.*|Environment=npm_package_version=${APP_VERSION}|" /etc/systemd/system/gitea-mirror.service
    msg_ok "Updated and rebuilt ${APP} to v${RELEASE}"

    msg_info "Restoring Data"
    cp /opt/gitea-mirror-backup/data/* /opt/gitea-mirror/data
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl daemon-reload
    systemctl start gitea-mirror
    msg_ok "Service Started"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4321${CL}"
