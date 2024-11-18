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
    __  ___                         
   /  |/  /__  ____ ___  ____  _____
  / /|_/ / _ \/ __ `__ \/ __ \/ ___/
 / /  / /  __/ / / / / / /_/ (__  ) 
/_/  /_/\___/_/ /_/ /_/\____/____/  
                                    
EOF
}
header_info
echo -e "Loading..."
APP="Memos"
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
if [[ ! -d /opt/memos ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP (Patience)"
cd /opt/memos
output=$(git pull --no-rebase)
if echo "$output" | grep -q "Already up to date."
then
  msg_ok "$APP is already up to date."
  exit
fi
systemctl stop memos
cd /opt/memos/web 
pnpm i --frozen-lockfile &>/dev/null
pnpm build &>/dev/null
cd /opt/memos
mkdir -p /opt/memos/server/dist
cp -r web/dist/* /opt/memos/server/dist/
cp -r web/dist/* /opt/memos/server/router/frontend/dist/ 
go build -o /opt/memos/memos -tags=embed bin/memos/main.go &>/dev/null
systemctl start memos
msg_ok "Updated $APP"
exit
}


start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:9030${CL} \n"
