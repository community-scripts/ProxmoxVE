#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tracktor.bytedge.in/

APP="tracktor"
var_tags="${var_tags:-car;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /opt/tracktor ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "tracktor" "javedh-dev/tracktor"; then
    msg_info "Stopping Service"
    systemctl stop tracktor
    msg_ok "Stopped Service"

    msg_info "Correcting Services"
    if [ -f /opt/tracktor/app/backend/.env ]; then
      mv /opt/tracktor/app/backend/.env /opt/tracktor.env
      echo 'AUTH_PIN=123456' >>/opt/tracktor.env
      sed -i 's|^EnvironmentFile=.*|EnvironmentFile=/opt/tracktor.env|' /etc/systemd/system/tracktor.service
      systemctl daemon-reload
    fi
    if [ ! -d "/opt/tracktor-data/uploads" ]; then
      mkdir -p /opt/tracktor-data/{uploads,logs}
      EXISTING_AUTH_PIN=$(grep '^AUTH_PIN=' /opt/tracktor.env 2>/dev/null | cut -d'=' -f2)
      AUTH_PIN=${EXISTING_AUTH_PIN:-123456}
      cat <<EOF >/opt/tracktor.env
NODE_ENV=production
DB_PATH=/opt/tracktor-data/tracktor.db
UPLOADS_DIR="/opt/tracktor-data/uploads"
LOG_DIR="/opt/tracktor-data/logs"
# If server host is not set by default it will run on all interfaces - 0.0.0.0
# SERVER_HOST="" 
SERVER_PORT=3000
# Set this if you want to secure your endpoints otherwise default will be "*"
CORS_ORIGINS="*"
# Set this if you are using backend and frontend separately.
# PUBLIC_API_BASE_URL=""
LOG_REQUESTS=true
LOG_LEVEL="info"
AUTH_PIN=${AUTH_PIN}
# PUBLIC_DEMO_MODE=false
# FORCE_DATA_SEED=false
EOF
    fi
    msg_ok "Corrected Services"

    setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tracktor" "javedh-dev/tracktor" "tarball" "latest" "/opt/tracktor"

    msg_info "Updating tracktor"
    cd /opt/tracktor
    $STD npm install
    $STD npm run build
    msg_ok "Updated tracktor"

    msg_info "Starting Service"
    systemctl start tracktor
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
