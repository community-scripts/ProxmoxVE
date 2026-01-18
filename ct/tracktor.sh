#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
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
    if [ ! -d "/opt/tracktor-data/uploads" ]; then
      mkdir -p /opt/tracktor-data/{uploads,logs}
    fi
    if ! grep -qxF 'BODY_SIZE_LIMIT=Infinity' /opt/tracktor.env; then
      rm /opt/tracktor.env
    cat <<EOF >/opt/tracktor.env
cat <<EOF >/opt/tracktor.env
NODE_ENV=production
# Set this to the path of the database file. Default - ./tracktor.db
DB_PATH=/opt/tracktor-data/tracktor.db
# Set this to the path of the uploads directory. Default - ./uploads
UPLOADS_DIR="/opt/tracktor-data/uploads"
# Set this to the path of the logs directory. Default - ./logs
LOG_DIR="/opt/tracktor-data/logs"
# Hostname to bind the server to. Default - 0.0.0.0
#HOST="0.0.0.0"
# Port to bind the server to. Default - 3000
#PORT=3000
# Set this to remove upload size limitations. Default - 512 Kb
BODY_SIZE_LIMIT=Infinity
# Enable request logging. Default - true
#LOG_REQUESTS=true
# Set the logging level. Options - error, warn, info, verbose, debug, silly. Default - info
#LOG_LEVEL="info"
# Enable demo mode. Default - false
#TRACKTOR_DEMO_MODE=false
# Force reseeding of data on every startup. Default - false
#FORCE_DATA_SEED=false
EOF
    fi
    msg_ok "Corrected Services"

    NODE_VERSION="24" setup_nodejs
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

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
