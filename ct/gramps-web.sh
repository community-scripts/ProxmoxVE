#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.grampsweb.org/ | Github: https://github.com/gramps-project/gramps-web

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

  if [[ ! -d /opt/gramps-web-api ]] || [[ ! -d /opt/gramps-web/frontend ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  PYTHON_VERSION="3.12" setup_uv
  NODE_VERSION="22" setup_nodejs

  if check_for_gh_release "gramps-web-api" "gramps-project/gramps-web-api"; then
    msg_info "Stopping Service"
    systemctl stop gramps-web
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gramps-web-api" "gramps-project/gramps-web-api" "tarball" "latest" "/opt/gramps-web-api"

    msg_info "Updating Gramps Web API"
    $STD uv venv -c -p python3.12 /opt/gramps-web/venv
    source /opt/gramps-web/venv/bin/activate
    $STD uv pip install --no-cache-dir --upgrade pip setuptools wheel
    $STD uv pip install --no-cache-dir gunicorn
    $STD uv pip install --no-cache-dir /opt/gramps-web-api
    msg_ok "Updated Gramps Web API"

    msg_info "Applying Database Migration"
    cd /opt/gramps-web-api
    GRAMPS_API_CONFIG=/opt/gramps-web/config/config.cfg \
      ALEMBIC_CONFIG=/opt/gramps-web-api/alembic.ini \
      GRAMPSHOME=/opt/gramps-web/data \
      GRAMPS_DATABASE_PATH=/opt/gramps-web/data/gramps/grampsdb \
      $STD /opt/gramps-web/venv/bin/python3 -m gramps_webapi user migrate
    msg_ok "Applied Database Migration"

    msg_info "Updating Gramps Addons"
    GRAMPS_VERSION=$(/opt/gramps-web/venv/bin/python3 -c "import gramps.version; print('%s%s' % (gramps.version.VERSION_TUPLE[0], gramps.version.VERSION_TUPLE[1]))" 2>/dev/null || echo "60")
    GRAMPS_PLUGINS_DIR="/opt/gramps-web/data/gramps/gramps${GRAMPS_VERSION}/plugins"
    mkdir -p "$GRAMPS_PLUGINS_DIR"
    $STD wget -q https://github.com/gramps-project/addons/archive/refs/heads/master.zip -O /tmp/gramps-addons.zip
    for addon in FilterRules JSON; do
      unzip -p /tmp/gramps-addons.zip "addons-master/gramps${GRAMPS_VERSION}/download/${addon}.addon.tgz" |
        tar -xz -C "$GRAMPS_PLUGINS_DIR"
    done
    rm -f /tmp/gramps-addons.zip
    msg_ok "Updated Gramps Addons"

    msg_info "Starting Service"
    systemctl start gramps-web
    msg_ok "Started Service"
  fi

  if check_for_gh_release "gramps-web" "gramps-project/gramps-web"; then
    msg_info "Stopping Service"
    systemctl stop gramps-web
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gramps-web" "gramps-project/gramps-web" "tarball" "latest" "/opt/gramps-web/frontend"

    msg_info "Updating Gramps Web Frontend"
    cd /opt/gramps-web/frontend
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    $STD corepack enable
    $STD npm install
    $STD npm run build
    msg_ok "Updated Gramps Web Frontend"

    msg_info "Starting Service"
    systemctl start gramps-web
    msg_ok "Started Service"
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
