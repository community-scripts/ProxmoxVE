#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: GitHub Copilot
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.grampsweb.org/

APP="gramps-web"
var_tags="${var_tags:-genealogy;family;collaboration}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/gramps-web-api ]]; then
    msg_error "No Gramps Web API Installation Found!"
    exit
  fi

  if [[ ! -d /opt/gramps-web/frontend ]]; then
    msg_error "No Gramps Web Frontend Installation Found!"
    exit
  fi

  if [[ ! -f /opt/gramps-web/config/config.cfg ]]; then
    msg_error "No Gramps Web Configuration Found!"
    exit
  fi

  PYTHON_VERSION="3.12" setup_uv
  NODE_VERSION="22" setup_nodejs

  UPDATE_AVAILABLE=0
  if check_for_gh_release "gramps-web-api" "gramps-project/gramps-web-api"; then
    UPDATE_AVAILABLE=1
  fi
  if check_for_gh_release "gramps-web" "gramps-project/gramps-web"; then
    UPDATE_AVAILABLE=1
  fi

  if [[ "$UPDATE_AVAILABLE" == "1" ]]; then
    msg_info "Stopping Service"
    systemctl stop gramps-web
    msg_ok "Stopped Service"

    if apt-cache show libgirepository1.0-dev >/dev/null 2>&1; then
      GI_DEV_PACKAGE="libgirepository1.0-dev"
    elif apt-cache show libgirepository-2.0-dev >/dev/null 2>&1; then
      GI_DEV_PACKAGE="libgirepository-2.0-dev"
    else
      msg_error "No supported girepository development package found!"
      exit
    fi

    msg_info "Ensuring Build Dependencies"
    $STD apt install -y \
      gobject-introspection \
      libcairo2-dev \
      libglib2.0-dev \
      pkg-config \
      "$GI_DEV_PACKAGE"
    msg_ok "Ensured Build Dependencies"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gramps-web-api" "gramps-project/gramps-web-api" "tarball" "latest" "/opt/gramps-web-api"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gramps-web" "gramps-project/gramps-web" "tarball" "latest" "/opt/gramps-web/frontend"

    msg_info "Updating Gramps Web API"
    $STD uv venv -c -p python3.12 /opt/gramps-web/venv
    source /opt/gramps-web/venv/bin/activate
    $STD uv pip install --no-cache-dir --upgrade pip setuptools wheel
    $STD uv pip install --no-cache-dir gunicorn
    $STD uv pip install --no-cache-dir /opt/gramps-web-api
    msg_ok "Updated Gramps Web API"

    msg_info "Updating Gramps Web Frontend"
    cd /opt/gramps-web/frontend
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    corepack enable
    $STD npm install
    $STD npm run build
    msg_ok "Updated Gramps Web Frontend"

    msg_info "Applying Database Migration"
    cd /opt/gramps-web-api
    GRAMPS_API_CONFIG=/opt/gramps-web/config/config.cfg \
      ALEMBIC_CONFIG=/opt/gramps-web-api/alembic.ini \
      GRAMPSHOME=/opt/gramps-web/data/gramps \
      GRAMPS_DATABASE_PATH=/opt/gramps-web/data/gramps/grampsdb \
      $STD /opt/gramps-web/venv/bin/python3 -m gramps_webapi user migrate
    msg_ok "Applied Database Migration"

    msg_info "Starting Service"
    systemctl start gramps-web
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
