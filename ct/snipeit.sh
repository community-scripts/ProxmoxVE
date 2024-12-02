#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

#Copyright (c) 2021-2024 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
function header_info {
clear
cat <<"EOF"
   _____       _                  __________
  / ___/____  (_)___  ___        /  _/_  __/
  \__ \/ __ \/ / __ \/ _ \______ / /  / /   
 ___/ / / / / / /_/ /  __/_____// /  / /    
/____/_/ /_/_/ .___/\___/     /___/ /_/     
            /_/                             
EOF
}
header_info
echo -e "Loading..."
APP="SnipeIT"

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
check_container_storage
check_container_resources
if [[ ! -d /opt/snipe-it ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/snipe/snipe-it/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Updating ${APP} to v${RELEASE}"
  apt-get update &>/dev/null
  apt-get -y upgrade &>/dev/null
  mv /opt/snipe-it /opt/snipe-it-backup
  cd /opt
  wget -q "https://github.com/snipe/snipe-it/archive/refs/tags/v${RELEASE}.zip" &>/dev/null
  unzip -q v${RELEASE}.zip
  mv snipe-it-${RELEASE} /opt/snipe-it
  cp /opt/snipe-it-backup/.env /opt/snipe-it/.env
  cp -r /opt/snipe-it-backup/public/uploads/ /opt/snipe-it/public/uploads/
  cp -r /opt/snipe-it-backup/storage/private_uploads /opt/snipe-it/storage/private_uploads
  cd /opt/snipe-it/
  export COMPOSER_ALLOW_SUPERUSER=1
  composer install --no-dev --prefer-source &>/dev/null
  composer dump-autoload &>/dev/null
  php artisan migrate --force &>/dev/null
  php artisan config:clear &>/dev/null
  php artisan route:clear &>/dev/null
  php artisan cache:clear &>/dev/null
  php artisan view:clear &>/dev/null
  chown -R www-data: /opt/snipe-it
  chmod -R 755 /opt/snipe-it
  rm -rf /opt/v${RELEASE}.zip
  rm -rf /opt/snipe-it-backup
  msg_ok "Updated ${APP} LXC"
else
  msg_ok "No update required. ${APP} is already at v${RELEASE}."
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
