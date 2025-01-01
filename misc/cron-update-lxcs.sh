#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/cron-update-lxcs.sh)"

clear
cat <<"EOF"
   ______                    __  __          __      __          __   _  ________
  / ____/________  ____     / / / /___  ____/ /___ _/ /____     / /  | |/ / ____/____
 / /   / ___/ __ \/ __ \   / / / / __ \/ __  / __ `/ __/ _ \   / /   |   / /   / ___/
/ /___/ /  / /_/ / / / /  / /_/ / /_/ / /_/ / /_/ / /_/  __/  / /___/   / /___(__  )
\____/_/   \____/_/ /_/   \____/ .___/\__,_/\__,_/\__/\___/  /_____/_/|_\____/____/
                              /_/
EOF

add() {
  while true; do
    read -p "This script will add a crontab schedule that updates all LXCs every Sunday at midnight. Proceed(y/n)?" yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
  sh -c '(crontab -l -u root 2>/dev/null; echo "0 0 * * 0 PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c \"\$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/update-lxcs-cron.sh)\" >>/var/log/update-lxcs-cron.log 2>/dev/null") | crontab -u root -'
  clear
  echo -e "\n To view Cron Update LXCs logs: cat /var/log/update-lxcs-cron.log"
}

remove() {
  (crontab -l | grep -v "github.com/community-scripts/ProxmoxVE/raw/main/misc/update-lxcs-cron.sh") | crontab -
  rm -rf /var/log/update-lxcs-cron.log
  echo "Removed Crontab Schedule from Proxmox VE"
}

OPTIONS=(Add "Add Crontab Schedule"
  Remove "Remove Crontab Schedule")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Cron Update LXCs" --menu "Select an option:" 10 58 2 \
  "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
"Add")
  add
  ;;
"Remove")
  remove
  ;;
*)
  echo "Exiting..."
  exit 0
  ;;
esac
