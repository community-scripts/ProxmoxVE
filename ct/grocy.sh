#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ____ __________  _______  __
  / __  / ___/ __ \/ ___/ / / /
 / /_/ / /  / /_/ / /__/ /_/ / 
 \__, /_/   \____/\___/\__, /  
/____/                /____/   
 
EOF
}
header_info
echo -e "Loading..."
APP="grocy"
var_disk="2"
var_cpu="1"
var_ram="512"
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
if [[ ! -f /etc/apache2/sites-available/grocy.conf ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
php_version=$(php -v | head -n 1 | awk '{print $2}')
if [[ ! $php_version == "8.3"* ]]; then
  msg_info "Updating PHP"
  curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ bookworm main" >/etc/apt/sources.list.d/php.list
  apt-get update
  apt-get install -y php8.3 php8.3-cli php8.3-{bz2,curl,mbstring,intl,sqlite3,fpm,gd,zip,xml}
  systemctl reload apache2
  apt autoremove
  msg_ok "Updated PHP"
fi
msg_info "Updating ${APP}"
bash /var/www/html/update.sh
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}${CL} \n"
