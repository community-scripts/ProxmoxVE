#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: remz1337
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ___         __  __               __  _ __  
   /   | __  __/ /_/ /_  ___  ____  / /_(_) /__
  / /| |/ / / / __/ __ \/ _ \/ __ \/ __/ / //_/
 / ___ / /_/ / /_/ / / /  __/ / / / /_/ / ,<   
/_/  |_\__,_/\__/_/ /_/\___/_/ /_/\__/_/_/|_|  
                                               
EOF
}
header_info
echo -e "Loading..."
APP="Authentik"
var_disk="12"
var_cpu="6"
var_ram="8192"
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
if [[ ! -f /etc/systemd/system/authentik-server.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/goauthentik/authentik/releases/latest | grep "tarball_url" | awk '{print substr($2, 2, length($2)-3)}')
if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "SET RESOURCES" "Please set the resources in your ${APP} LXC to ${var_cpu}vCPU and ${var_ram}RAM for the build process before continuing" 10 75
  msg_info "Stopping ${APP}"
  systemctl stop authentik-server
  systemctl stop authentik-worker
  msg_ok "Stopped ${APP}"

  msg_info "Building Authentik website"
  mkdir -p /opt/authentik
  wget -qO authentik.tar.gz "${RELEASE}"
  tar -xzf authentik.tar.gz -C /opt/authentik --strip-components 1 --overwrite
  rm -rf authentik.tar.gz
  cd /opt/authentik/website
  npm install >/dev/null 2>&1
  npm run build-bundled >/dev/null 2>&1
  cd /opt/authentik/web
  npm install >/dev/null 2>&1
  npm run build >/dev/null 2>&1
  msg_ok "Built Authentik website"

  msg_info "Installing Python Dependencies"
  cd /opt/authentik
  poetry install --only=main --no-ansi --no-interaction --no-root >/dev/null 2>&1
  poetry export --without-hashes --without-urls -f requirements.txt --output requirements.txt >/dev/null 2>&1
  pip install --no-cache-dir -r requirements.txt >/dev/null 2>&1
  pip install . >/dev/null 2>&1
  msg_ok "Installed Python Dependencies"

  msg_info "Updating ${APP} to v${RELEASE} (Patience)" 
  cp -r /opt/authentik/authentik/blueprints /opt/authentik/blueprints
  cd /opt/authentik
  bash /opt/authentik/lifecycle/ak migrate >/dev/null 2>&1
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to v${RELEASE}"

  msg_info "Starting Authentik"
  systemctl start authentik-server
  systemctl start authentik-worker
  msg_ok "Started Authentik"
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
         ${BL}http://${IP}:9000/if/flow/initial-setup/${CL} \n"