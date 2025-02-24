#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://cronicle.net/

APP="Cronicle"
var_tags="task-scheduler"
var_cpu="1"
var_ram="512"
var_disk="2"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 2 \
    "1" "Update ${APP}" ON \
    "2" "Install ${APP} Worker" OFF \
    3>&1 1>&2 2>&3)

  if [ "$UPD" == "1" ]; then
    if [[ ! -d /opt/cronicle ]]; then
      msg_error "No ${APP} Installation Found!"
      exit
    fi
    if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
      if ! command -v npm >/dev/null 2>&1; then
        echo "Installing NPM..."
        $STD apt-get install -y npm
        echo "Installed NPM..."
      fi
    fi
    msg_info "Updating ${APP}"
    $STD /opt/cronicle/bin/control.sh upgrade
    msg_ok "Updated ${APP}"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
      if ! command -v npm >/dev/null 2>&1; then
        echo "Installing NPM..."
        $STD apt-get install -y npm
        echo "Installed NPM..."
      fi
    fi
    LATEST=$(curl -sL https://api.github.com/repos/jhuckaby/Cronicle/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
    IP=$(hostname -I | awk '{print $1}')
    msg_info "Installing Dependencies"

    $STD apt-get install -y git
    $STD apt-get install -y make
    $STD apt-get install -y g++
    $STD apt-get install -y gcc
    $STD apt-get install -y ca-certificates
    $STD apt-get install -y gnupg
    msg_ok "Installed Dependencies"

    msg_info "Setting up Node.js Repository"
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
    msg_ok "Set up Node.js Repository"

    msg_info "Installing Node.js"
    $STD apt-get update
    $STD apt-get install -y nodejs
    msg_ok "Installed Node.js"

    msg_info "Installing Cronicle Worker"
    mkdir -p /opt/cronicle
    cd /opt/cronicle
    $STD tar zxvf <(curl -fsSL https://github.com/jhuckaby/Cronicle/archive/${LATEST}.tar.gz) --strip-components 1
    $STD npm install
    $STD node bin/build.js dist
    sed -i "s/localhost:3012/${IP}:3012/g" /opt/cronicle/conf/config.json
    $STD /opt/cronicle/bin/control.sh start
    $STD cp /opt/cronicle/bin/cronicled.init /etc/init.d/cronicled
    chmod 775 /etc/init.d/cronicled
    $STD update-rc.d cronicled defaults
    msg_ok "Installed Cronicle Worker"
    echo -e "\n Add Masters secret key to /opt/cronicle/conf/config.json \n"
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3012${CL}"