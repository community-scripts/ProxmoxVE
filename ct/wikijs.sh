#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/ | Github: https://github.com/requarks/wiki

APP="Wikijs"
var_tags="${var_tags:-wiki}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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
  if [[ ! -d /opt/wikijs ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="26" NODE_MODULE="yarn,node-gyp" setup_nodejs

  if check_for_gh_release "wikijs" "requarks/wiki-v2"; then
    # Installs before February 2025 use SQLite, newer ones PostgreSQL
    SQLITE_INSTALL=$([[ -f /opt/wikijs/db.sqlite ]] && echo "true" || echo "false")

    msg_info "Stopping Service"
    systemctl stop wikijs
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    mkdir -p /opt/wikijs-backup
    if [[ "$SQLITE_INSTALL" == "true" ]]; then
      cp /opt/wikijs/db.sqlite /opt/wikijs-backup
    fi
    cp -R /opt/wikijs/{config.yml,/data} /opt/wikijs-backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wikijs" "requarks/wiki-v2" "prebuild" "latest" "/opt/wikijs" "wiki-js.tar.gz"

    msg_info "Restoring Data"
    cp -R /opt/wikijs-backup/* /opt/wikijs
    if [[ "$SQLITE_INSTALL" == "true" ]]; then
      $STD npm rebuild sqlite3
    fi
    rm -rf /opt/wikijs-backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start wikijs
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
