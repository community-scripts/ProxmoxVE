#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
  _______               _ _ 
 /_  __(_)___ _____    (_|_)
  / / / / __ `/ __ \  / / / 
 / / / / /_/ / / / / / / /  
/_/ /_/\__,_/_/ /_/_/ /_/   
                 /___/      
EOF
}
header_info
echo -e "Loading..."
APP="Tianji"
var_disk="12"
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
if [[ ! -d /opt/tianji ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/msgbyte/tianji/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP} Service"
  systemctl stop tianji
  msg_ok "Stopped ${APP} Service"
  msg_info "Updating ${APP} to ${RELEASE}"
  cd /opt
  cp /opt/tianji/src/server/.env /opt/.env
  mv /opt/tianji /opt/tianji_bak
  wget -q "https://github.com/msgbyte/tianji/archive/refs/tags/v${RELEASE}.zip"
  unzip -q v${RELEASE}.zip
  mv tianji-${RELEASE} /opt/tianji
  cd tianji
  pnpm install --filter @tianji/client... --config.dedupe-peer-dependents=false --frozen-lockfile >/dev/null 2>&1
  pnpm build:static >/dev/null 2>&1
  pnpm install --filter @tianji/server... --config.dedupe-peer-dependents=false >/dev/null 2>&1
  mkdir -p ./src/server/public >/dev/null 2>&1
  cp -r ./geo ./src/server/public >/dev/null 2>&1
  pnpm build:server >/dev/null 2>&1
  mv /opt/.env /opt/tianji/src/server/.env 
  cd src/server
  pnpm db:migrate:apply >/dev/null 2>&1
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"
  msg_info "Starting ${APP}"
  systemctl start tianji
  msg_ok "Started ${APP}"
  msg_info "Cleaning up"
  rm -R /opt/v${RELEASE}.zip
  rm -rf /opt/tianji_bak
  rm -rf /opt/tianji/src/client
  rm -rf /opt/tianji/website
  rm -rf /opt/tianji/reporter
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
         ${BL}http://${IP}:12345${CL} \n"
