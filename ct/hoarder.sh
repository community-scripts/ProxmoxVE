#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: MickLesk (Canbiz) & vhsdream
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  __                     __
   / / / /___  ____ __________/ /__  _____
  / /_/ / __ \/ __ `/ ___/ __  / _ \/ ___/
 / __  / /_/ / /_/ / /  / /_/ /  __/ /
/_/ /_/\____/\__,_/_/   \__,_/\___/_/

EOF
}
header_info
echo -e "Loading..."
APP="Hoarder"
TAGS="bookmark;links"
var_disk="8"
var_cpu="4"
var_ram="4096"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
check_container_storage
check_container_resources
if [[ ! -d /opt/hoarder ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/hoarder-app/hoarder/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
PREV_VERSION=$(cat /opt/${APP}_version.txt)
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "${PREV_VERSION}" ]]; then
  msg_info "Stopping Services"
  systemctl stop hoarder-web hoarder-workers hoarder-browser
  msg_ok "Stopped Services"

  msg_info "Updating ${APP} to v${RELEASE}"
  cd /opt
  mv /opt/hoarder /opt/hoarder_bak
  wget -q "https://github.com/hoarder-app/hoarder/archive/refs/tags/v${RELEASE}.zip"
  unzip -q v${RELEASE}.zip
  mv hoarder-${RELEASE} /opt/hoarder
  cd /opt/hoarder/apps/web
  pnpm install --frozen-lockfile &>/dev/null
  cd /opt/hoarder/apps/workers
  pnpm install --frozen-lockfile >/dev/null 2>&1
  cd /opt/hoarder/apps/web
  export NEXT_TELEMETRY_DISABLED=1
  pnpm exec next build --experimental-build-mode compile >/dev/null 2>&1
  cp -r /opt/hoarder/apps/web/.next/standalone/apps/web/server.js /opt/hoarder/apps/web
  export DATA_DIR=/opt/hoarder_data
  cd /opt/hoarder/packages/db
  pnpm migrate >/dev/null 2>&1
  echo "${RELEASE}" >/opt/${APP}_version.txt
  cp /opt/hoarder_bak/.env /opt/hoarder/.env
  sed -i "s/SERVER_VERSION=${PREV_VERSION}/SERVER_VERSION=${RELEASE}/" /opt/hoarder/.env
  msg_ok "Updated ${APP} to ${RELEASE}"
  msg_info "Starting ${APP} Services"
  systemctl start hoarder-browser hoarder-workers hoarder-web
  msg_ok "Started ${APP}"
  msg_info "Cleaning up"
  rm -R /opt/v${RELEASE}.zip
  rm -rf /opt/hoarder_bak
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required.  ${APP} is already at ${RELEASE}."
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"
