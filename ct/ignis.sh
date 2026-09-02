#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Nystik-gh/ignis

APP="Ignis"
var_tags="${var_tags:-notes;obsidian}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_arm64="${var_arm64:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/ignis ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ignis" "Nystik-gh/ignis"; then
    msg_info "Stopping Service"
    systemctl stop ignis
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ignis" "Nystik-gh/ignis" "tarball"

    msg_info "Building Ignis"
    cd /opt/ignis
    export NODE_OPTIONS="--max-old-space-size=4096"
    export IGNIS_BUILD="$(cat ~/.ignis)"
    $STD npm ci --ignore-scripts
    $STD npm run build
    $STD npm install -g @electron/asar
    msg_ok "Built Ignis"

    msg_info "Checking Obsidian Web Assets"
    OBSIDIAN_VERSION=$(grep -oP 'OBSIDIAN_VERSION=\K[0-9.]+' /opt/ignis/apps/ignis-server/Dockerfile | head -n1)
    [[ -z "$OBSIDIAN_VERSION" ]] && OBSIDIAN_VERSION="$(cat /opt/ignis_data/obsidian.version 2>/dev/null)"
    if [[ -n "$OBSIDIAN_VERSION" && "$OBSIDIAN_VERSION" != "$(cat /opt/ignis_data/obsidian.version 2>/dev/null)" ]]; then
      rm -rf /opt/ignis_data/obsidian-app
      mkdir -p /opt/ignis_data/obsidian-app
      curl -fsSL -o /tmp/obsidian.asar.gz "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/obsidian-${OBSIDIAN_VERSION}.asar.gz"
      gunzip -f /tmp/obsidian.asar.gz
      $STD asar extract /tmp/obsidian.asar /opt/ignis_data/obsidian-app
      rm -f /tmp/obsidian.asar
      echo "${OBSIDIAN_VERSION}" >/opt/ignis_data/obsidian.version
    fi
    msg_ok "Checked Obsidian Web Assets"

    msg_info "Starting Service"
    systemctl start ignis
    systemctl reload nginx
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}${CL}"
