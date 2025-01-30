#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
   ________                    __   _  ________
  / ____/ /__  ____ _____     / /  | |/ / ____/
 / /   / / _ \/ __ `/ __ \   / /   |   / /
/ /___/ /  __/ /_/ / / / /  / /___/   / /___
\____/_/\___/\__,_/_/ /_/  /_____/_/|_\____/

EOF
}
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC Updater" --yesno "This Will Clean logs, cache and update apt lists on selected LXC Containers. Proceed?" 10 58 || exit
NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\nSelect containers to skip from cleaning:\n" \
  16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit  

function clean_container() {
  container=$1
  header_info
  name=$(pct exec "$container" hostname)
  echo -e "${BL}[Info]${GN} Cleaning ${name} ${CL} \n"
  pct exec $container -- bash -c "apt-get -y --purge autoremove && apt-get -y autoclean && bash <(curl -fsSL https://github.com/community-scripts/ProxmoxVE/raw/main/misc/clean.sh) && rm -rf /var/lib/apt/lists/* && apt-get update"
}
for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    header_info
    echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}"
    sleep 1
  else
    os=$(pct config "$container" | awk '/^ostype/ {print $2}')
    if [ "$os" != "debian" ] && [ "$os" != "ubuntu" ]; then
      header_info
      echo -e "${BL}[Info]${GN} Skipping ${name} ${RD}$container is not Debian or Ubuntu ${CL} \n"
      sleep 1
      continue
    fi

    status=$(pct status $container)
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
      pct start $container
      echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
      sleep 5
      clean_container $container
      echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
      pct shutdown $container &
    elif [ "$status" == "status: running" ]; then
      clean_container $container
    fi
  fi
done

wait
header_info
echo -e "${GN} Finished, Selected Containers Cleaned. ${CL} \n"
