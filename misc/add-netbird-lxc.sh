#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    _   __     __  ____  _          __
   / | / /__  / /_/ __ )(_)________/ /
  /  |/ / _ \/ __/ __  / / ___/ __  / 
 / /|  /  __/ /_/ /_/ / / /  / /_/ / 
/_/ |_/\___/\__/_____/_/_/   \__,_/  

EOF
}
header_info
set -e
while true; do
  read -p "This will add NetBird to an existing LXC Container ONLY. Proceed(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done
header_info
echo "Loading..."

function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}

NODE=$(hostname)
MSG_MAX_LENGTH=0
while read -r line; do
  TAG=$(echo "$line" | awk '{print $1}')
  ITEM=$(echo "$line" | awk '{print substr($0,36)}')
  OFFSET=2
  if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
    MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
  fi
  CTID_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')

while [ -z "${CTID:+x}" ]; do
  CTID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --radiolist \
    "\nSelect a container to add NetBird to:\n" \
    16 $(($MSG_MAX_LENGTH + 23)) 6 \
    "${CTID_MENU[@]}" 3>&1 1>&2 2>&3) || exit
done

LXC_STATUS=$(pct status "$CTID" | awk '{print $2}')
if [[ "$LXC_STATUS" != "running" ]]; then
  msg "\e[1;33m The container $CTID is not running. Starting it now...\e[0m"
  pct start "$CTID"
  while [[ "$(pct status "$CTID" | awk '{print $2}')" != "running" ]]; do
    msg "\e[1;33m Waiting for the container to start...\e[0m"
    sleep 2
  done
  msg "\e[1;32m Container $CTID is now running.\e[0m"
fi

DISTRO=$(pct exec "$CTID" -- cat /etc/os-release | grep -w "ID" | cut -d'=' -f2 | tr -d '"')
if [[ "$DISTRO" != "debian" && "$DISTRO" != "ubuntu" ]]; then
  msg "\e[1;31m Error: This script only supports Debian or Ubuntu LXC containers. Detected: $DISTRO. Aborting...\e[0m"
  exit 1
fi

CTID_CONFIG_PATH=/etc/pve/lxc/${CTID}.conf
cat <<EOF >>$CTID_CONFIG_PATH
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
EOF
header_info
msg "Installing NetBird..."
pct exec "$CTID" -- bash -c '
apt install -y ca-certificates gpg &>/dev/null
wget -qO- https://pkgs.netbird.io/debian/public.key | gpg --dearmor >/usr/share/keyrings/netbird-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main" >/etc/apt/sources.list.d/netbird.list
apt-get update &>/dev/null
apt-get install -y netbird-ui &>/dev/null
' || exit
msg "\e[1;32m ✔ Installed NetBird.\e[0m"
sleep 2
msg "\e[1;31m Reboot ${CTID} LXC to apply the changes, then run netbird up in the LXC console\e[0m"
