#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ____  ___          _______     
  / __ \/ (_)   _____/_  __(_)___ 
 / / / / / / | / / _ \/ / / / __ \
/ /_/ / / /| |/ /  __/ / / / / / /
\____/_/_/ |___/\___/_/ /_/_/ /_/ 
                                  
EOF
}

IP=$(hostname -I | awk '{print $1}')
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
APP="OliveTin"
hostname="$(hostname)"
set-e
header_info

while true; do
    read -p "This will Install ${APP} on $hostname. Proceed(y/n)?" yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
done
header_info

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_info "Installing ${APP}"
wget -q https://github.com/OliveTin/OliveTin/releases/latest/download/OliveTin_linux_amd64.deb
dpkg -i OliveTin_linux_amd64.deb &>/dev/null
systemctl enable --now OliveTin &>/dev/null
rm OliveTin_linux_amd64.deb
msg_ok "Installed ${APP} on $hostname"

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://$IP:1337${CL} \n"
