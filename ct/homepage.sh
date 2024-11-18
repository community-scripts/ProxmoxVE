#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  __                                          
   / / / /___  ____ ___  ___  ____  ____ _____ ____ 
  / /_/ / __ \/ __ `__ \/ _ \/ __ \/ __ `/ __ `/ _ \
 / __  / /_/ / / / / / /  __/ /_/ / /_/ / /_/ /  __/
/_/ /_/\____/_/ /_/ /_/\___/ .___/\__,_/\__, /\___/ 
                          /_/          /____/       
EOF
}
header_info
echo -e "Loading..."
APP="Homepage"
var_disk="3"
var_cpu="2"
var_ram="1024"
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
if [[ ! -d /opt/homepage ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
  if ! command -v npm >/dev/null 2>&1; then
    echo "Installing NPM..."
    apt-get install -y npm >/dev/null 2>&1
    npm install -g pnpm >/dev/null 2>&1
    echo "Installed NPM..."
  fi
fi
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
  npx update-browserslist-db@latest
  pnpm install
  pnpm build
  systemctl start homepage
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated Homepage to v${RELEASE}"
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
