#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | DevelopmentCats | AlphaLawless
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://romm.app | Github: https://github.com/rommapp/romm

APP="RomM"
var_tags="${var_tags:-emulation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/romm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "romm" "rommapp/romm"; then
    msg_info "Stopping Services"
    systemctl stop romm-backend romm-worker romm-scheduler romm-watcher
    msg_ok "Stopped Services"

    create_backup /opt/romm/.env
    BACKUP_DIR=/opt/romm-players.backup create_backup \
      /opt/romm/frontend/dist/assets/emulatorjs \
      /opt/romm/frontend/dist/assets/ruffle

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "romm" "rommapp/romm" "tarball" "latest" "/opt/romm"

    restore_backup

    msg_info "Updating ROMM"
    cd /opt/romm
    $STD uv sync --all-extras
    cd /opt/romm/backend
    $STD uv run alembic upgrade head
    if [[ -f /opt/romm/backend/utils/rom_patcher/package.json ]]; then
      cd /opt/romm/backend/utils/rom_patcher
      $STD npm install --ignore-scripts --no-audit --no-fund
      if [[ -d node_modules/rom-patcher/rom-patcher-js ]]; then
        rm -rf rom-patcher-js
        cp -r node_modules/rom-patcher/rom-patcher-js ./rom-patcher-js
      fi
      rm -rf node_modules
    fi
    cd /opt/romm/frontend
    $STD npm install
    $STD npm run build
    # Merge static assets into dist folder
    cp -rf /opt/romm/frontend/assets/* /opt/romm/frontend/dist/assets/
    mkdir -p /opt/romm/frontend/dist/assets/romm
    ROMM_BASE=$(grep '^ROMM_BASE_PATH=' /opt/romm/.env | cut -d'=' -f2)
    ROMM_BASE=${ROMM_BASE:-/var/lib/romm}
    ln -sfn "$ROMM_BASE"/resources /opt/romm/frontend/dist/assets/romm/resources
    ln -sfn "$ROMM_BASE"/assets /opt/romm/frontend/dist/assets/romm/assets
    if [[ -f /etc/angie/http.d/romm.conf ]]; then
      sed -i "s|alias .*/library/;|alias ${ROMM_BASE}/library/;|" /etc/angie/http.d/romm.conf
      systemctl reload angie
    elif [[ -f /etc/nginx/sites-available/romm ]]; then
      sed -i "s|alias .*/library/;|alias ${ROMM_BASE}/library/;|" /etc/nginx/sites-available/romm
      systemctl reload nginx
    fi
    msg_ok "Updated ROMM"

    msg_info "Starting Services"
    systemctl start romm-backend romm-worker romm-scheduler romm-watcher
    msg_ok "Started Services"
    msg_ok "Updated successfully"
  fi

  if check_for_gh_release "EmulatorJS" "EmulatorJS/EmulatorJS" "v4.2.3"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "EmulatorJS" "EmulatorJS/EmulatorJS" "prebuild" "v4.2.3" "/opt/romm/frontend/dist/assets/emulatorjs" "4.2.3.7z"
    systemctl restart romm-backend romm-worker romm-scheduler romm-watcher
    msg_ok "Updated EmulatorJS successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
