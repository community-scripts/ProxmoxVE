#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gethomepage.dev/

APP="Homepage"
var_tags="dashboard"
var_cpu="2"
var_ram="4096"
var_disk="6"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/homepage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "Installing NPM..."
      $STD apt-get install -y npm
      $STD npm install -g pnpm
      echo "Installed NPM..."
    fi
  fi
  LOCAL_IP=$(hostname -I | awk '{print $1}')
  RELEASE=$(curl -s https://api.github.com/repos/gethomepage/homepage/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Updating Homepage to v${RELEASE} (Patience)"
    systemctl stop homepage
    wget -q https://github.com/gethomepage/homepage/archive/refs/tags/v${RELEASE}.tar.gz
    tar -xzf v${RELEASE}.tar.gz
    rm -rf v${RELEASE}.tar.gz
    cp -r homepage-${RELEASE}/* /opt/homepage/
    rm -rf homepage-${RELEASE}
    cd /opt/homepage
    $STD pnpm install
    $STD npx --yes update-browserslist-db@latest
    export NEXT_PUBLIC_VERSION="v$RELEASE"
    export NEXT_PUBLIC_REVISION="source"
    export NEXT_TELEMETRY_DISABLED=1
    $STD pnpm build
    if [[ ! -f /opt/homepage/.env ]]; then
        echo "HOMEPAGE_ALLOWED_HOSTS=localhost:3000,${LOCAL_IP}:3000" > /opt/homepage/.env
    fi
    systemctl start homepage
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated Homepage to v${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
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
