#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ShaneIsrael/fireshare

APP="Fireshare"
var_tags="${var_tags:-sharing;video}"
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
  if [[ ! -d /opt/fireshare ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "fireshare" "ShaneIsrael/fireshare"; then
    msg_info "Stopping Service"
    systemctl stop fireshare
    msg_ok "Stopped Service"

    create_backup /opt/fireshare/fireshare.env
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "fireshare" "ShaneIsrael/fireshare" "tarball"
    restore_backup
    rm -f /usr/local/bin/fireshare

    if ! grep -q "__FIRESHARE_PORT__" /etc/nginx/nginx.conf; then
      cp /opt/fireshare/app/nginx/prod.conf /etc/nginx/nginx.conf
      sed -i 's|root /processed/|root /opt/fireshare-processed/|g' /etc/nginx/nginx.conf
      sed -i 's/^user[[:space:]]\+nginx;/user  root;/' /etc/nginx/nginx.conf
      sed -i 's|root[[:space:]]\+/app/build;|root /opt/fireshare/app/client/build;|' /etc/nginx/nginx.conf
      sed -i 's/__FIRESHARE_PORT__/80/g' /etc/nginx/nginx.conf
      cp /opt/fireshare/app/nginx/error.html /etc/nginx/
      cp /opt/fireshare/app/nginx/api_unavailable.html /etc/nginx/
    fi
    msg_info "Configuring Fireshare"

    cd /opt/fireshare
    $STD uv venv --clear
    $STD .venv/bin/python -m ensurepip --upgrade
    $STD .venv/bin/python -m pip install --upgrade --break-system-packages pip
    $STD .venv/bin/python -m pip install --no-cache-dir --break-system-packages --ignore-installed app/server
    cp .venv/bin/fireshare /usr/local/bin/fireshare
    export FLASK_APP="/opt/fireshare/app/server/fireshare:create_app()"
    export DATA_DIRECTORY=/opt/fireshare-data
    export IMAGE_DIRECTORY=/opt/fireshare-images
    export VIDEO_DIRECTORY=/opt/fireshare-videos
    export PROCESSED_DIRECTORY=/opt/fireshare-processed
    $STD uv run flask db upgrade
    cd /opt/fireshare/app/client
    $STD npm install
    $STD npm run build
    msg_ok "Configured Fireshare"

    msg_info "Starting Service"
    systemctl start fireshare
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  cleanup_lxc

  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
