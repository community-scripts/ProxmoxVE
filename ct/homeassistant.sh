#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    __  __                        ___              _      __              __ 
   / / / /___  ____ ___  ___     /   |  __________(_)____/ /_____ _____  / /_
  / /_/ / __ \/ __  __ \/ _ \   / /| | / ___/ ___/ / ___/ __/ __  / __ \/ __/
 / __  / /_/ / / / / / /  __/  / ___ |(__  |__  ) (__  ) /_/ /_/ / / / / /_  
/_/ /_/\____/_/ /_/ /_/\___/  /_/  |_/____/____/_/____/\__/\__,_/_/ /_/\__/  
 
EOF
}
header_info
echo -e "Loading..."
APP="Home Assistant"
var_disk="16"
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
  if [[ ! -d /var/lib/docker/volumes/hass_config/_data ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 4 \
    "1" "Update ALL Containers" ON \
    "2" "Remove ALL Unused Images" OFF \
    "3" "Install HACS" OFF \
    "4" "Install FileBrowser" OFF \
    3>&1 1>&2 2>&3)

  if [ "$UPD" == "1" ]; then
    msg_info "Updating All Containers"
    CONTAINER_LIST="${1:-$(docker ps -q)}"
    for container in ${CONTAINER_LIST}; do
      CONTAINER_IMAGE="$(docker inspect --format "{{.Config.Image}}" --type container ${container})"
      RUNNING_IMAGE="$(docker inspect --format "{{.Image}}" --type container "${container}")"
      docker pull "${CONTAINER_IMAGE}"
      LATEST_IMAGE="$(docker inspect --format "{{.Id}}" --type image "${CONTAINER_IMAGE}")"
      if [[ "${RUNNING_IMAGE}" != "${LATEST_IMAGE}" ]]; then
        echo "Updating ${container} image ${CONTAINER_IMAGE}"
        DOCKER_COMMAND="$(runlike "${container}")"
        docker rm --force "${container}"
        eval ${DOCKER_COMMAND}
      fi
    done
    msg_ok "Updated All Containers"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    msg_info "Removing ALL Unused Images"
    docker image prune -af
    msg_ok "Removed ALL Unused Images"
    exit
  fi
  if [ "$UPD" == "3" ]; then
    msg_info "Installing Home Assistant Community Store (HACS)"
    apt update &>/dev/null
    apt install unzip &>/dev/null
    cd /var/lib/docker/volumes/hass_config/_data
    bash <(curl -fsSL https://get.hacs.xyz) &>/dev/null
    msg_ok "Installed Home Assistant Community Store (HACS)"
    echo -e "\n Reboot Home Assistant and clear browser cache then Add HACS integration.\n"
    exit
  fi
  if [ "$UPD" == "4" ]; then
    IP=$(hostname -I | awk '{print $1}')
    msg_info "Installing FileBrowser"
    RELEASE=$(curl -fsSL https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g')
    curl -fsSL https://github.com/filebrowser/filebrowser/releases/download/v2.23.0/linux-amd64-filebrowser.tar.gz | tar -xzv -C /usr/local/bin &>/dev/null
    filebrowser config init -a '0.0.0.0' &>/dev/null
    filebrowser config set -a '0.0.0.0' &>/dev/null
    filebrowser users add admin helper-scripts.com --perm.admin &>/dev/null
    msg_ok "Installed FileBrowser"

    msg_info "Creating Service"
    service_path="/etc/systemd/system/filebrowser.service"
    echo "[Unit]
Description=Filebrowser
After=network-online.target
[Service]
User=root
WorkingDirectory=/root/
ExecStart=/usr/local/bin/filebrowser -r /
[Install]
WantedBy=default.target" >$service_path

    systemctl enable --now filebrowser.service &>/dev/null
    msg_ok "Created Service"

    msg_ok "Completed Successfully!\n"
    echo -e "FileBrowser should be reachable by going to the following URL.
         ${BL}http://$IP:8080${CL}   admin|helper-scripts.com\n"
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8123${CL}
Portainer should be reachable by going to the following URL.
         ${BL}https://${IP}:9443${CL}\n"
