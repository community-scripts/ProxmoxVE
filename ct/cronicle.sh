#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ______                 _      __   
  / ____/________  ____  (_)____/ /__ 
 / /   / ___/ __ \/ __ \/ / ___/ / _ \
/ /___/ /  / /_/ / / / / / /__/ /  __/
\____/_/   \____/_/ /_/_/\___/_/\___/ 
                                      
EOF
}
header_info
echo -e "Loading..."
APP="Cronicle"
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
UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 2 \
  "1" "Update ${APP}" ON \
  "2" "Install ${APP} Worker" OFF \
  3>&1 1>&2 2>&3)

if [ "$UPD" == "1" ]; then
if [[ ! -d /opt/cronicle ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "Installing NPM..."
      apt-get install -y npm >/dev/null 2>&1
      echo "Installed NPM..."
    fi
  fi
msg_info "Updating ${APP}"
/opt/cronicle/bin/control.sh upgrade &>/dev/null
msg_ok "Updated ${APP}"
exit
fi
if [ "$UPD" == "2" ]; then
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "Installing NPM..."
      apt-get install -y npm >/dev/null 2>&1
      echo "Installed NPM..."
    fi
  fi
LATEST=$(curl -sL https://api.github.com/repos/jhuckaby/Cronicle/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
IP=$(hostname -I | awk '{print $1}')
msg_info "Installing Dependencies"

apt-get install -y git &>/dev/null
apt-get install -y make &>/dev/null
apt-get install -y g++ &>/dev/null
apt-get install -y gcc &>/dev/null
apt-get install -y ca-certificates &>/dev/null
apt-get install -y gnupg &>/dev/null
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
apt-get update &>/dev/null
apt-get install -y nodejs &>/dev/null
msg_ok "Installed Node.js"

msg_info "Installing Cronicle Worker"
mkdir -p /opt/cronicle
cd /opt/cronicle
tar zxvf <(curl -fsSL https://github.com/jhuckaby/Cronicle/archive/${LATEST}.tar.gz) --strip-components 1 &>/dev/null
npm install &>/dev/null
node bin/build.js dist &>/dev/null
sed -i "s/localhost:3012/${IP}:3012/g" /opt/cronicle/conf/config.json
/opt/cronicle/bin/control.sh start &>/dev/null
cp /opt/cronicle/bin/cronicled.init /etc/init.d/cronicled &>/dev/null
chmod 775 /etc/init.d/cronicled
update-rc.d cronicled defaults &>/dev/null
msg_ok "Installed Cronicle Worker"
echo -e "\n Add Masters secret key to /opt/cronicle/conf/config.json \n"
exit
fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Primary should be reachable by going to the following URL.
         ${BL}http://${IP}:3012${CL} \n"
