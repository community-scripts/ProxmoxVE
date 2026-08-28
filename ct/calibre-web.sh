#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: mikolaj92
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/janeczku/calibre-web

APP="calibre-web"
var_tags="${var_tags:-media;books}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/calibre-web ]]; then
    msg_error "No Calibre-Web Installation Found!"
    exit
  fi

  if check_for_gh_release "Calibre-Web" "janeczku/calibre-web"; then
    msg_info "Stopping Service"
    systemctl stop calibre-web
    msg_ok "Stopped Service"

    create_backup /opt/calibre-web/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Calibre-Web" "janeczku/calibre-web" "prebuild" "latest" "/opt/calibre-web" "calibreweb*.tar.gz"
    setup_uv

    msg_info "Installing Dependencies"
    cd /opt/calibre-web
    $STD uv venv --clear /opt/calibre-web/.venv
    $STD uv pip install --python /opt/calibre-web/.venv/bin/python --no-cache-dir --upgrade pip setuptools wheel
    $STD uv pip install --python /opt/calibre-web/.venv/bin/python --no-cache-dir .
    msg_ok "Installed Dependencies"

    sed -i 's|^ExecStart=.*|ExecStart=/opt/calibre-web/.venv/bin/cps -p /opt/calibre-web/data/app.db|' /etc/systemd/system/calibre-web.service
    if ! grep -q '^Environment=HOME=' /etc/systemd/system/calibre-web.service; then
      sed -i '/^ExecStart=/i Environment=HOME=/opt/calibre-web/data' /etc/systemd/system/calibre-web.service
    fi
    $STD systemctl daemon-reload

    restore_backup

    mkdir -p /opt/calibre-web-library
    if [[ -f /opt/calibre-web/data/metadata.db && ! -f /opt/calibre-web-library/metadata.db ]]; then
      msg_info "Migrating Calibre Library to its own directory"
      find /opt/calibre-web/data -mindepth 1 -maxdepth 1 ! -name app.db ! -name .calibre-web -exec mv -t /opt/calibre-web-library -- {} +
      msg_ok "Migrated Calibre Library"
    fi
    if [[ ! -f /opt/calibre-web-library/metadata.db ]]; then
      msg_info "Creating Empty Calibre Library"
      $STD calibredb list --with-library /opt/calibre-web-library
      msg_ok "Created Empty Calibre Library"
    fi

    msg_info "Starting Service"
    systemctl start calibre-web
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
echo -e "${GATEWAY}${BGN}http://${IP}:8083${CL}"
