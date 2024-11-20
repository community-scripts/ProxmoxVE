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
    ___       __                 __                  __               
   /   | ____/ /   _____  ____  / /___  __________  / /   ____  ____ _
  / /| |/ __  / | / / _ \/ __ \/ __/ / / / ___/ _ \/ /   / __ \/ __ `/
 / ___ / /_/ /| |/ /  __/ / / / /_/ /_/ / /  /  __/ /___/ /_/ / /_/ / 
/_/  |_\__,_/ |___/\___/_/ /_/\__/\__,_/_/   \___/_____/\____/\__, /  
                                                             /____/   
EOF
}
header_info
echo -e "Loading..."
APP="AdventureLog"
var_disk="7"
var_cpu="2"
var_ram="2048"
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
if [[ ! -d /opt/adventurelog ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/seanmorley15/AdventureLog/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping Services"
  systemctl stop adventurelog-backend
  systemctl stop adventurelog-frontend
  msg_ok "Services Stopped"

  msg_info "Updating ${APP} to ${RELEASE}"
  cp /opt/adventurelog/backend/server/.env /opt/server.env
  cp /opt/adventurelog/frontend/.env /opt/frontend.env
  wget -q "https://github.com/seanmorley15/AdventureLog/archive/refs/tags/v${RELEASE}.zip"
  unzip -q v${RELEASE}.zip
  mv AdventureLog-${RELEASE} /opt/adventurelog
  mv /opt/server.env /opt/adventurelog/backend/server/.env
  cd /opt/adventurelog/backend/server
  pip install --upgrade pip &>/dev/null
  pip install -r requirements.txt &>/dev/null
  python3 manage.py collectstatic --noinput &>/dev/null
  python3 manage.py migrate &>/dev/null
  
  mv /opt/frontend.env /opt/adventurelog/frontend/.env
  cd /opt/adventurelog/frontend
  pnpm install &>/dev/null
  pnpm run build &>/dev/null
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP}"

  msg_info "Starting Services"
  systemctl start adventurelog-backend
  systemctl start adventurelog-frontend
  msg_ok "Started Services"

  msg_info "Cleaning Up"
  rm -rf v${RELEASE}.zip
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"
