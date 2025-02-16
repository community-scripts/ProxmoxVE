#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____                                          __   _  ________   ____       __     __     
   / __ \_________  _  ______ ___  ____  _  __   / /  | |/ / ____/  / __ \___  / /__  / /____ 
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  / /   |   / /      / / / / _ \/ / _ \/ __/ _ \
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /___/   / /___   / /_/ /  __/ /  __/ /_/  __/
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|  /_____/_/|_\____/  /_____/\___/_/\___/\__/\___/ 
                                                                                              
EOF
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        printf " [%c]  " "$spinstr"
        spinstr=${spinstr#?}${spinstr%"${spinstr#?}"}
        sleep $delay
        printf "\r"
    done
    printf "    \r"
}

set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
TAB="  "
CM="${TAB}✔️${TAB}${CL}"

header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC Deletion" --yesno "This will delete LXC containers. Proceed?" 10 58 || exit

NODE=$(hostname)
containers=$(pct list | tail -n +2 | awk '{print $0 " " $4}')

if [ -z "$containers" ]; then
    whiptail --title "LXC Container Delete" --msgbox "No LXC containers available!" 10 60
    exit 1
fi

menu_items=()
FORMAT="%-10s %-15s %-10s"

while read -r container; do
    container_id=$(echo $container | awk '{print $1}')
    container_name=$(echo $container | awk '{print $2}')
    container_status=$(echo $container | awk '{print $3}')
    formatted_line=$(printf "$FORMAT" "$container_name" "$container_status")
    menu_items+=("$container_id" "$formatted_line" "OFF")
done <<< "$containers"

CHOICES=$(whiptail --title "LXC Container Delete" \
                   --checklist "Select LXC containers to delete:" 25 60 13 \
                   "${menu_items[@]}" 3>&2 2>&1 1>&3)

if [ -z "$CHOICES" ]; then
    whiptail --title "LXC Container Delete" \
             --msgbox "No containers selected!" 10 60
    exit 1
fi

read -p "Delete containers manually or automatically? (Default: manual) m/a: " DELETE_MODE
DELETE_MODE=${DELETE_MODE:-m}

selected_ids=$(echo "$CHOICES" | tr -d '"' | tr -s ' ' '\n')

for container_id in $selected_ids; do
    status=$(pct status $container_id)

    if [ "$status" == "status: running" ]; then
        echo -e "${BL}[Info]${GN} Stopping container $container_id...${CL}"
        pct stop $container_id &
        sleep 5
        echo -e "${BL}[Info]${GN} Container $container_id stopped.${CL}"
    fi

    if [[ "$DELETE_MODE" == "a" ]]; then
        echo -e "${BL}[Info]${GN} Automatically deleting container $container_id...${CL}"
        pct destroy "$container_id" -f &
        pid=$!
        spinner $pid
        [ $? -eq 0 ] && echo "Container $container_id deleted." || whiptail --title "Error" --msgbox "Failed to delete container $container_id." 10 60
    else
        read -p "Delete container $container_id? (y/N): " CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo -e "${BL}[Info]${GN} Deleting container $container_id...${CL}"
            pct destroy "$container_id" -f &
            pid=$!
            spinner $pid
            [ $? -eq 0 ] && echo "Container $container_id deleted." || whiptail --title "Error" --msgbox "Failed to delete container $container_id." 10 60
        else
            echo -e "${BL}[Info]${RD} Skipping container $container_id...${CL}"
        fi
    fi
done

header_info
echo -e "${GN}Deletion process completed.${CL}\n"
