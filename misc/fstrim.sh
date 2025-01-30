#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
    _______ __                     __                    ______     _
   / ____(_) /__  _______  _______/ /____  ____ ___     /_  __/____(_)___ ___
  / /_  / / / _ \/ ___/ / / / ___/ __/ _ \/ __ `__ \     / / / ___/ / __ `__ \
 / __/ / / /  __(__  ) /_/ (__  ) /_/  __/ / / / / /    / / / /  / / / / / / /
/_/   /_/_/\___/____/\__, /____/\__/\___/_/ /_/ /_/    /_/ /_/  /_/_/ /_/ /_/
                    /____/
EOF
}
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
header_info
echo "Loading..."

ROOT_FS=$(df -Th "/" | awk 'NR==2 {print $2}')
if [ "$ROOT_FS" != "ext4" ]; then
    echo "Root filesystem is not ext4. Exiting script."
    exit 1
fi

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC Filesystem Trim" --yesno "The LXC containers will undergo the fstrim command. Proceed?" 10 58 || exit
NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\nSelect containers to skip from trimming:\n" \
  16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit  

function trim_container() {
  local container=$1
  header_info
  echo -e "${BL}[Info]${GN} Trimming ${BL}$container${CL} \n"
  local before_trim=$(lvs | awk -F '[[:space:]]+' 'NR>1 && (/Data%|'"vm-$container"'/) {gsub(/%/, "", $7); print $7}')
  echo -e "${RD}Data before trim $before_trim%${CL}"
  pct fstrim $container
  local after_trim=$(lvs | awk -F '[[:space:]]+' 'NR>1 && (/Data%|'"vm-$container"'/) {gsub(/%/, "", $7); print $7}')
  echo -e "${GN}Data after trim $after_trim%${CL}"
  sleep 1.5
}



for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    header_info
    echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}"
    sleep 1
  else
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "true" ]; then
      header_info
      echo -e "${BL}[Info]${GN} Skipping ${container} ${RD}$container is a template ${CL} \n"
      sleep 1
      continue
    fi
      trim_container $container
  fi
done

wait
header_info
echo -e "${GN} Finished, LXC Containers Trimmed. ${CL} \n"
