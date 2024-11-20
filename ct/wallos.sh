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
 _       __      ____          
| |     / /___ _/ / /___  _____
| | /| / / __ `/ / / __ \/ ___/
| |/ |/ / /_/ / / / /_/ (__  ) 
|__/|__/\__,_/_/_/\____/____/  
                               
EOF
}
header_info
echo -e "Loading..."
APP="Wallos"
var_disk="5"
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
if [[ ! -d /opt/wallos ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/ellite/Wallos/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Updating ${APP} to ${RELEASE}"
  cd /opt
  wget -q "https://github.com/ellite/Wallos/archive/refs/tags/v${RELEASE}.zip"
  mkdir -p /opt/logos
  mv /opt/wallos/db/wallos.db /opt/wallos.db
  mv /opt/wallos/images/uploads/logos /opt/logos/
  unzip -q v${RELEASE}.zip
  rm -rf /opt/wallos
  mv Wallos-${RELEASE} /opt/wallos
  rm -rf /opt/wallos/db/wallos.empty.db
  mv /opt/wallos.db /opt/wallos/db/wallos.db
  mv /opt/logos/* /opt/wallos/images/uploads/logos
  chown -R www-data:www-data /opt/wallos
  chmod -R 755 /opt/wallos
  mkdir -p /var/log/cron
  curl http://localhost/endpoints/db/migrate.php &>/dev/null
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP}"

  msg_info "Reload Apache2"
  systemctl reload apache2
  msg_ok "Apache2 Reloaded"

  msg_info "Cleaning Up"
  rm -R /opt/v${RELEASE}.zip 
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
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP} ${CL} \n"
