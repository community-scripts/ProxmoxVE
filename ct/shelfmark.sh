#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/calibrain/shelfmark

APP="shelfmark"
var_tags="${var_tags:-ebooks}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/shelfmark ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" setup_nodejs
  PYTHON_VERSION="3.12" setup_uv

  if check_for_gh_release "shelfmark" "calibrain/shelfmark"; then
    msg_info "Stopping Service(s)"
    systemctl stop shelfmark
    [[ -f /etc/systemd/system/chromium.service ]] && systemctl stop chromium
    msg_ok "Stopped Service(s)"

    [[ -f /etc/systemd/system/flaresolverr.service ]] && if check_for_gh_release "flaresolverr" "Flaresolverr/Flaresolverr"; then
      msg_info "Stopping FlareSolverr service"
      systemctl stop flaresolverr
      msg_ok "Stopped FlareSolverr service"
      
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "flaresolverr" "FlareSolverr/FlareSolverr" "prebuild" "latest" "/opt/flaresolverr" "flaresolverr_linux_x64.tar.gz"
      
      msg_info "Starting FlareSolverr Service"
      systemctl start flaresolverr
      msg_ok "Started FlareSolverr Service"
      msg_ok "Updated FlareSolverr"
    fi
    
    cp /opt/shelfmark/start.sh /opt/start.sh.bak
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "shelfmark" "calibrain/shelfmark" "tarball" "latest" "/opt/shelfmark"
    RELEASE_VERSION=$(cat "$HOME/.shelfmark")

    msg_info "Updating Shelfmark"
    sed -i "s/^RELEASE_VERSION=.*/RELEASE_VERSION=$RELEASE_VERSION/" /etc/shelfmark/.env
    cd /opt/shelfmark/src/frontend
    $STD npm ci
    $STD npm run build
    mv /opt/shelfmark/src/frontend/dist /opt/shelfmark/frontend-dist
    cd /opt/shelfmark
    $STD uv venv -c ./venv
    $STD source ./venv/bin/activate
    $STD uv pip install -r ./requirements-base.txt
    if [[ $(sed -n '/_BYPASS=/s/[^=]*=//p' /etc/shelfmark/.env) == "true" ]] && [[ $(sed -n '/BYPASSER=/s/[^=]*=//p' /etc/shelfmark/.env) == "false" ]]; then
      $STD uv pip install -r ./requirements-shelfmark.txt
    fi
    mv /opt/start.sh.bak /opt/shelfmark/start.sh
    msg_ok "Updated Shelfmark"

    msg_info "Starting Service(s)"
    systemctl start shelfmark
    [[ -f /etc/systemd/system/chromium.service ]] && systemctl start chromium
    msg_ok "Started Service(s)"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8084${CL}"
