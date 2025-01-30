#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
    clear
    cat <<"EOF"
    _   __     __  ____        __
   / | / /__  / /_/ __ \____ _/ /_____ _
  /  |/ / _ \/ __/ / / / __ `/ __/ __ `/
 / /|  /  __/ /_/ /_/ / /_/ / /_/ /_/ /
/_/ |_/\___/\__/_____/\__,_/\__/\__,_/

EOF
}

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
silent() { "$@" >/dev/null 2>&1; }
set -e
header_info
echo "Loading..."
function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

install() {
  header_info
  while true; do
    read -p "Are you sure you want to install NetData on Proxmox VE host. Proceed(y/n)?" yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
  header_info
  read -r -p "Verbose mode? <y/N> " prompt
  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  STD=""
  else
  STD="silent"
  fi
  header_info

  msg_info "Setting up repository"
  wget -q https://repo.netdata.cloud/repos/repoconfig/debian/bookworm/netdata-repo_2-2+debian12_all.deb
  $STD dpkg -i netdata-repo_2-2+debian12_all.deb
  rm -rf netdata-repo_2-2+debian12_all.deb
  msg_ok "Set up repository"

  msg_info "Installing Netdata"
  $STD apt-get update
  $STD apt-get install -y netdata
  msg_ok "Installed Netdata"
  msg_ok "Completed Successfully!\n"
  echo -e "\n Netdata should be reachable at${BL} http://$(hostname -I | awk '{print $1}'):19999 ${CL}\n"
}

uninstall() {
  header_info
  read -r -p "Verbose mode? <y/N> " prompt
  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  STD=""
  else
  STD="silent"
  fi
  header_info

  msg_info "Uninstalling Netdata"
  systemctl stop netdata
  rm -rf /var/log/netdata /var/lib/netdata /var/cache/netdata /etc/netdata/go.d
  rm -rf /etc/apt/trusted.gpg.d/netdata-archive-keyring.gpg /etc/apt/sources.list.d/netdata.list
  $STD apt-get remove --purge -y netdata netdata-repo
  systemctl daemon-reload
  $STD apt autoremove -y
  $STD userdel netdata
  msg_ok "Uninstalled Netdata"
  msg_ok "Completed Successfully!\n"
}

if ! pveversion | grep -Eq "pve-manager/(8\.[0-9])"; then
  echo -e "This version of Proxmox Virtual Environment is not supported"
  echo -e "Requires PVE Version 8.0 or higher"
  echo -e "Exiting..."
  sleep 2
  exit
fi

OPTIONS=(Install "Install NetData on Proxmox VE" \
         Uninstall "Uninstall NetData from Proxmox VE")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "NetData" --menu "Select an option:" 10 58 2 \
          "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
  "Install")
    install
    ;;
  "Uninstall")
    uninstall
    ;;
  *)
    echo "Exiting..."
    exit 0
    ;;
esac
