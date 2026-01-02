#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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

set -eEuo pipefail
BL="\033[36m"
RD="\033[01;31m"
CM='\xE2\x9C\x94\033'
GN="\033[1;92m"
CL="\033[m"

header_info
echo "Loading..."

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC Updater" --yesno "This will clean logs, cache and update package lists on selected LXC Containers. Proceed?" 10 58

NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0

while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')

excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\nSelect containers to skip from cleaning:\n" \
  16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

if [ $? -ne 0 ]; then
  exit
fi

function run_lxc_clean() {
  local container=$1
  header_info

  case "$os" in
  alpine)
    # shellcheck disable=SC2016
    pct exec "$container" -- sh -c '
      BL="\033[36m"; GN="\033[1;92m"; CL="\033[m"
      echo -e "${BL}[Info]${GN} Cleaning $(hostname) (Alpine)${CL}\n"
      apk cache clean
      find /var/log -type f -delete 2>/dev/null
      find /tmp -mindepth 1 -delete 2>/dev/null
    '
    ;;
  centos | fedora)
    # shellcheck disable=SC2016
    pct exec "$container" -- sh -c '
      BL="\033[36m"; GN="\033[1;92m"; CL="\033[m"
      echo -e "${BL}[Info]${GN} Cleaning $(hostname) (CentOS/fedora)${CL}\n"
      dnf -y autoremove
      dnf -y clean all
      rm -rf ~/.cache /var/cache/yum /var/cache/dnf
      find /var/log -type f -delete 2>/dev/null
      find /tmp -mindepth 1 -delete 2>/dev/null
    '
    ;;
  ubuntu | debian | devuan)
    # shellcheck disable=SC2016
    pct exec "$container" -- sh -c '
      BL="\033[36m"; GN="\033[1;92m"; CL="\033[m"
      echo -e "${BL}[Info]${GN} Cleaning $(hostname) (Debian/Ubuntu)${CL}\n"
      apt-get -y --purge autoremove
      apt-get -y autoclean
      rm -rf /var/lib/apt/lists/*
      find /var/cache -type f -delete 2>/dev/null
      find /var/log -type f -delete 2>/dev/null
      find /tmp -mindepth 1 -delete 2>/dev/null
    '
    ;;
  esac
}

for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ "${excluded_containers[*]}" =~ $container ]]; then
    header_info
    echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}"
    sleep 1
    continue
  fi

  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  # Supported: ubuntu debian devuan centos fedora alpine
  if ! [[ 'alpine centos debian devuan fedora ubuntu' =~ (^|[[:space:]])"$os"($|[[:space:]]) ]]; then
    header_info
    echo -e "${BL}[Info]${GN} Skipping ${RD}$container\npct ostype ($os) is not supported.\nSupported ostypes:" \
      "\n\talpine\n\tcentos\n\tdebian\n\tdevuan\n\tfedora\n\tubuntu${CL}"
    sleep 1
    continue
  fi

  status=$(pct status "$container")
  template=$(pct config "$container" | grep -q "template:" && echo "true" || echo "false")

  if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
    echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
    pct start "$container"
    echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
    sleep 5
    run_lxc_clean "$container"
    echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
    pct shutdown "$container" &
  elif [ "$status" == "status: running" ]; then
    run_lxc_clean "$container"
  fi
done

wait
header_info
echo -e "${GN} Finished, Selected Containers Cleaned. ${CL} \n"
