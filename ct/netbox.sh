#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: bvdberg01
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
               __  __              
   ____  ___  / /_/ /_  ____  _  __
  / __ \/ _ \/ __/ __ \/ __ \| |/_/
 / / / /  __/ /_/ /_/ / /_/ />  <  
/_/ /_/\___/\__/_.___/\____/_/|_|  
                                   
EOF
}
header_info
echo -e "Loading..."
APP="Netbox"
var_disk="4"
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
if [[ ! -f /opt/netbox/netbox/netbox/configuration.py ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/netbox-community/netbox/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [ ! -d "/opt/netbox-${RELEASE}" ]; then
  msg_info "Updating $APP LXC"
  apt-get update &>/dev/null
  apt-get -y upgrade &>/dev/null
  
  OLD_VERSION_PATH=$(ls -d /opt/netbox-*/)
  wget -q "https://github.com/netbox-community/netbox/archive/refs/tags/v${RELEASE}.tar.gz"
  tar -xzf "v${RELEASE}.tar.gz" -C /opt
  ln -sfn "/opt/netbox-${RELEASE}/" /opt/netbox
  rm "v${RELEASE}.tar.gz"
  
  cp "${OLD_VERSION_PATH}netbox/netbox/configuration.py" /opt/netbox/netbox/netbox/
  cp -pr "${OLD_VERSION_PATH}netbox/media/" /opt/netbox/netbox/
  cp -r "${OLD_VERSION_PATH}netbox/scripts" /opt/netbox/netbox/
  cp -r "${OLD_VERSION_PATH}netbox/reports" /opt/netbox/netbox/
  cp "${OLD_VERSION_PATH}gunicorn.py" /opt/netbox/

  if [ -d "${OLD_VERSION_PATH}local_requirements.txt" ]; then
    cp "${OLD_VERSION_PATH}local_requirements.txt" /opt/netbox/
  fi

  if [ -d "${OLD_VERSION_PATH}netbox/netbox/ldap_config.py" ]; then
    cp "${OLD_VERSION_PATH}netbox/netbox/ldap_config.py" /opt/netbox/netbox/netbox/
  fi

  rm -r "${OLD_VERSION_PATH}"
  /opt/netbox/upgrade.sh &>/dev/null
  systemctl restart --now netbox netbox-rq
  msg_ok "Updated $APP LXC"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}https://${IP}${CL} \n"
