#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: jeroenzwart
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
     ______                     __          __   _  ________
   / ____/  _____  _______  __/ /____     / /  | |/ / ____/
  / __/ | |/_/ _ \/ ___/ / / / __/ _ \   / /   |   / /     
 / /____>  </  __/ /__/ /_/ / /_/  __/  / /___/   / /___   
/_____/_/|_|\___/\___/\__,_/\__/\___/  /_____/_/|_\____/   
                                                           
EOF
}
set -eEuo pipefail
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC Execute" --yesno "This will execute a command inside selected LXC Containers. Proceed?" 10 58
NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\nSelect containers to skip from executing:\n" \
  16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

if [ $? -ne 0 ]; then
  exit
fi


read -r -p "Enter here command for inside the containers: " custom_command

header_info
echo "One moment please...\n"

function execute_in() {
  container=$1
  name=$(pct exec "$container" hostname)
  echo -e "${BL}[Info]${GN} Execute inside${BL} ${name}${GN} with output: ${CL}"
  pct exec "$container" -- bash -c "${custom_command}" | tee
}

for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}"
  else
    os=$(pct config "$container" | awk '/^ostype/ {print $2}')
    if [ "$os" != "debian" ] && [ "$os" != "ubuntu" ]; then
      echo -e "${BL}[Info]${GN} Skipping ${name} ${RD}$container is not Debian or Ubuntu ${CL}"
      continue
    fi

    status=$(pct status "$container")
    template=$(pct config "$container" | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL}"
      pct start "$container"
      echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL}"
      sleep 5
      execute_in "$container"
      echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL}"
      pct shutdown "$container" &
    elif [ "$status" == "status: running" ]; then
      execute_in "$container"
    fi
  fi
done

wait

echo -e "${GN} Finished, execute command inside selected containers. ${CL} \n"
