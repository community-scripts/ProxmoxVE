#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

clear
if command -v pveversion >/dev/null 2>&1; then echo -e "⚠️  Can't Run from the Proxmox Shell"; exit; fi
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
APP="Home Assistant Container"
while true; do
    read -p "This will restore ${APP} from a backup. Proceed(y/n)?" yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
done
clear
function header_info {
    cat <<"EOF"
    __  __                        ___              _      __              __              
   / / / /___  ____ ___  ___     /   |  __________(_)____/ /_____ _____  / /_   
  / /_/ / __ \/ __ `__ \/ _ \   / /| | / ___/ ___/ / ___/ __/ __ `/ __ \/ __/  
 / __  / /_/ / / / / / /  __/  / ___ |(__  |__  ) (__  ) /_/ /_/ / / / / /_   
/_/ /_/\____/_/ /_/ /_/\___/  /_/  |_/____/____/_/____/\__/\__,_/_/ /_/\__/   
                        RESTORE FROM BACKUP                                
EOF
}

header_info

function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YW}${msg}..."
}
function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}
function msg_error() {
    local msg="$1"
    echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}
if [ -z "$(ls -A /var/lib/docker/volumes/hass_config/_data/backups/)" ]; then
    msg_error "No backups found! \n"
    exit 1
fi
DIR=/var/lib/docker/volumes/hass_config/_data/restore
if [ -d "$DIR" ]; then
    msg_ok "Restore Directory Exists."
else
    mkdir -p /var/lib/docker/volumes/hass_config/_data/restore
    msg_ok "Created Restore Directory."
fi
cd /var/lib/docker/volumes/hass_config/_data/backups/
PS3="Please enter your choice: "
files="$(ls -A .)"
select filename in ${files}; do
    msg_ok "You selected ${BL}${filename}${CL}"
    break
done
msg_info "Stopping Home Assistant"
docker stop homeassistant &>/dev/null
msg_ok "Stopped Home Assistant"
msg_info "Restoring Home Assistant using ${filename}"
tar xvf ${filename} -C /var/lib/docker/volumes/hass_config/_data/restore &>/dev/null
cd /var/lib/docker/volumes/hass_config/_data/restore
tar -xvf homeassistant.tar.gz &>/dev/null
if ! command -v rsync >/dev/null 2>&1; then apt-get install -y rsync &>/dev/null; fi
rsync -a /var/lib/docker/volumes/hass_config/_data/restore/data/ /var/lib/docker/volumes/hass_config/_data
rm -rf /var/lib/docker/volumes/hass_config/_data/restore/*
msg_ok "Restore Complete"
msg_ok "Starting Home Assistant \n"
docker start homeassistant
