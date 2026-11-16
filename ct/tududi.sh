#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tududi.com/ | Github: https://github.com/chrisvel/tududi

APP="Tududi"
var_tags="${var_tags:-todo-app}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/tududi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  RELEASE=""
  if ! grep -qs '^DATABASE_URL=' /opt/tududi/backend/.env; then
    RELEASE="v1.15.0"
    msg_warn "Tududi 2.0 runs on PostgreSQL only, so this SQLite install stays on 1.15.0"
    msg_warn "To move to 2.0, export in Settings > Backups and import into a new Tududi LXC"
  fi

  if check_for_gh_release "tududi" "chrisvel/tududi" "${RELEASE}" "2.0 needs PostgreSQL"; then
    msg_info "Stopping Service"
    systemctl stop tududi
    msg_ok "Stopped Service"

    msg_info "Backing up env file"
    if [[ -f /opt/tududi/backend/.env ]]; then
      cp /opt/tududi/backend/.env /opt/tududi.env
    else
      cp /opt/tududi/.env /opt/tududi.env
    fi
    if ! grep -q '^TUDUDI_UPLOAD_PATH=' /opt/tududi.env; then
      mkdir -p /opt/tududi-uploads
      [[ -d /opt/tududi/backend/uploads ]] && cp -a /opt/tududi/backend/uploads/. /opt/tududi-uploads/
      echo "TUDUDI_UPLOAD_PATH=/opt/tududi-uploads" >>/opt/tududi.env
    fi
    msg_ok "Backed up env file"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tududi" "chrisvel/tududi" "tarball" "${CHECK_UPDATE_RELEASE}" "/opt/tududi"

    msg_info "Updating Tududi"
    cd /opt/tududi
    $STD npm install
    export NODE_ENV=production
    $STD npm run frontend:build
    mv ./dist ./backend
    mv /opt/tududi.env /opt/tududi/backend/.env
    DB="$(sed -n '/^DB_FILE/s/[^=]*=//p' /opt/tududi/backend/.env)"
    export DB_FILE="$DB"
    sed -i -e 's|/tududi$|/tududi/backend|' \
      -e 's|npm run start|bash /opt/tududi/backend/cmd/start.sh|' \
      /etc/systemd/system/tududi.service
    systemctl daemon-reload
    msg_ok "Updated Tududi"

    msg_info "Starting Service"
    systemctl start tududi
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
echo -e "${GATEWAY}${BGN}http://${IP}:3002${CL}"
