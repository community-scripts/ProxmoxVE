#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   _____
  / ___/____  ____  ____  __________
  \__ \/ __ \/ __ \/ __ `/ ___/ ___/
 ___/ / /_/ / / / / /_/ / /  / /
/____/\____/_/ /_/\__,_/_/  /_/

EOF
}
header_info
echo -e "Loading..."
APP="Sonarr"
var_disk="4"
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
if [[ ! -d /var/lib/sonarr/ ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP v4"
systemctl stop sonarr.service
wget -q -O SonarrV4.tar.gz 'https://services.sonarr.tv/v1/download/main/latest?version=4&os=linux&arch=x64'
tar -xzf SonarrV4.tar.gz
rm -rf /opt/Sonarr
mv Sonarr /opt
rm -rf SonarrV4.tar.gz
systemctl start sonarr.service
msg_ok "Updated $APP v4"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8989${CL} \n"
