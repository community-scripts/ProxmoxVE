#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____  ____  ____ _  __ __  _______ _  __    __   _  ________   ____  ________    __________________
   / __ \/ __ \/ __ \ |/ //  |/  / __ \ |/ /   / /  | |/ / ____/  / __ \/ ____/ /   / ____/_  __/ ____/
  / /_/ / /_/ / / / /   // /|_/ / / / /   /   / /   |   / /      / / / / __/ / /   / __/   / / / __/   
 / ____/ _, _/ /_/ /   |/ /  / / /_/ /   |   / /___/   / /___   / /_/ / /___/ /___/ /___  / / / /___   
/_/   /_/ |_|\____/_/|_/_/  /_/\____/_/|_|  /_____/_/|_\____/  /_____/_____/_____/_____/ /_/ /_____/   
                                                                                                       
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
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC Deletion" --yesno "This Will Delete LXC Containers. Proceed?" 10 58 || exit

NODE=$(hostname)

# Get list of containers with ID and hostname
containers=$(pct list | tail -n +2 | awk '{print $0 " " $4}')

# Exit if no containers are found
if [ -z "$containers" ]; then
    whiptail --title "LXC Container Delete" --msgbox "There are no LXC Container available!" 10 60
    exit 1
fi

menu_items=()
FORMAT="%-10s %-15s %-10s"

# Format container data for menu display
while read -r container; do
    container_id=$(echo $container | awk '{print $1}')
    container_name=$(echo $container | awk '{print $2}')
    container_status=$(echo $container | awk '{print $3}')
    formatted_line=$(printf "$FORMAT" "$container_name" "$container_status")
    menu_items+=("$container_id" "$formatted_line" "OFF")
done <<< "$containers"

# Display selection menu
CHOICES=$(whiptail --title "LXC Container Delete" \
                   --checklist "Choose LXC container to delete:" 25 60 13 \
                   "${menu_items[@]}" 3>&2 2>&1 1>&3)

if [ -z "$CHOICES" ]; then
    whiptail --title "LXC Container Delete" \
             --msgbox "No containers have been selected!" 10 60
    exit 1
fi

# Process selected containers
selected_ids=$(echo "$CHOICES" | tr -d '"' | tr -s ' ' '\n')

for container_id in $selected_ids; do
    status=$(pct status $container_id)

    # Stop container if running
    if [ "$status" == "status: running" ]; then
        echo -e "${BL}[Info]${GN} Stop container $container_id...${CL}"
        pct stop $container_id &
        sleep 5
        echo -e "${BL}[Info]${GN} Container $container_id stopped.${CL}"
    fi

    # Confirm deletion
    read -p "Are you sure you want to delete Container $container_id? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${BL}[Info]${GN} Deleting container $container_id...${CL}"
        pct destroy "$container_id" -f &
        pid=$!
        spinner $pid
        if [ $? -eq 0 ]; then
            echo "Container $container_id was successfully deleted."
        else
            whiptail --title "Error" --msgbox "Error deleting container $container_id." 10 60
        fi
    elif [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        echo -e "${BL}[Info]${RD} Skipping container $container_id...${CL}"
    else
        echo -e "${RD}[Error]${CL} Invalid input, skipping container $container_id."
    fi
done

header_info
echo -e "${GN}The deletion process has been completed.${CL}\n"
