#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____             __    ____       __         _     __   ______                           __     _________            __
   / __ \___  ____  / /   / __ \___  / /_  _____(_)___/ /  /_  __/___  _____________  ____  / /_   / ____/ (_)__  ____  / /_
  / /_/ / _ \/ __ `/ /___/ / / / _ \/ __ \/ ___/ / __  /    / / / __ \/ ___/ ___/ _ \/ __ \/ __/  / /   / / / _ \/ __ \/ __/
 / _, _/  __/ /_/ / /___/ /_/ /  __/ /_/ / /  / / /_/ /    / / / /_/ / /  / /  /  __/ / / / /_   / /___/ / /  __/ / / / /_
/_/ |_|\___/\__,_/_/   /_____/\___/_.___/_/  /_/\__,_/    /_/  \____/_/  /_/   \___/_/ /_/\__/   \____/_/_/\___/_/ /_/\__/

EOF
}
header_info
echo -e "Loading..."
APP="RDTClient"
var_disk="4"
var_cpu="1"
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
if [[ ! -d /opt/rdtc/ ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping ${APP}"
systemctl stop rdtc
msg_ok "Stopped ${APP}"

msg_info "Updating ${APP}"
if dpkg-query -W dotnet-sdk-8.0 >/dev/null 2>&1; then
    apt-get remove --purge -y dotnet-sdk-8.0 &>/dev/null
    apt-get install -y dotnet-sdk-9.0 &>/dev/null
fi
mkdir -p rdtc-backup
cp -R /opt/rdtc/appsettings.json rdtc-backup/
wget -q https://github.com/rogerfar/rdt-client/releases/latest/download/RealDebridClient.zip
unzip -oqq RealDebridClient.zip -d /opt/rdtc
cp -R rdtc-backup/appsettings.json /opt/rdtc/
msg_ok "Updated ${APP}"

msg_info "Starting ${APP}"
systemctl start rdtc
msg_ok "Started ${APP}"

msg_info "Cleaning Up"
rm -rf rdtc-backup RealDebridClient.zip
msg_ok "Cleaned"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:6500${CL} \n"
