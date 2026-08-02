#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/transmute-app/transmute

APP="Transmute"
var_tags="${var_tags:-files;converter}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/transmute ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  fetch_and_deploy_gh_release "calibre" "kovidgoyal/calibre" "prebuild" "latest" "/opt/calibre" "calibre-*-$(arch_resolve "x86_64" "arm64").txz"
  ln -sf /opt/calibre/ebook-convert /usr/bin/ebook-convert
  fetch_and_deploy_gh_release "drawio" "jgraph/drawio-desktop" "binary" "latest" "" "drawio-$(arch_resolve)-*.deb"
  fetch_and_deploy_gh_release "pandoc" "jgm/pandoc" "binary" "latest" "" "pandoc-*-$(arch_resolve).deb"

  if check_for_gh_release "transmute" "transmute-app/transmute"; then
    msg_info "Stopping Service"
    systemctl stop transmute
    msg_ok "Stopped Service"

    create_backup /opt/transmute/backend/.env /opt/transmute/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "transmute" "transmute-app/transmute" "tarball"

    restore_backup

    msg_info "Updating Python Dependencies"
    cd /opt/transmute
    $STD uv venv --clear /opt/transmute/.venv
    $STD uv pip install --python /opt/transmute/.venv/bin/python -r requirements.txt
    msg_ok "Updated Python Dependencies"

    msg_info "Rebuilding Frontend"
    cd /opt/transmute/frontend
    $STD npm ci
    $STD npm run build
    msg_ok "Rebuilt Frontend"


    msg_info "Starting Service"
    systemctl start transmute
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
echo -e "${GATEWAY}${BGN}http://${IP}:3313${CL}"
