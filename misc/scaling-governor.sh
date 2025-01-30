#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
set -e
header_info() {
clear
cat <<EOF
  ________  __  __  _____
 / ___/ _ \/ / / / / ___/__ _  _____ _______  ___  _______
/ /__/ ___/ /_/ / / (_ / _ \ |/ / -_) __/ _ \/ _ \/ __(_-<
\___/_/   \____/  \___/\___/___/\__/_/ /_//_/\___/_/ /___/
EOF
}
header_info
whiptail --backtitle "Proxmox VE Helper Scripts" --title "CPU Scaling Governors" --yesno "View/Change CPU Scaling Governors. Proceed?" 10 58 || exit
current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
GOVERNORS_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  GOVERNORS_MENU+=("$TAG" "$ITEM " "OFF")
done < <(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors | tr ' ' '\n' | grep -v "$current_governor")
scaling_governor=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Current CPU Scaling Governor is set to $current_governor" --checklist "\nSelect the Scaling Governor to use:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${GOVERNORS_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit
[ -z "$scaling_governor" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "No CPU Scaling Governor Selected" --msgbox "It appears that no CPU Scaling Governor was selected" 10 68
    clear
    exit
}
echo "${scaling_governor}" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Current CPU Scaling Governor" "\nCurrent CPU Scaling Governor has been set to $current_governor\n" 10 60
CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CPU Scaling Governor" --menu "This will establish a crontab to maintain the CPU Scaling Governor configuration across reboots.\n \nSetup a crontab?" 14 68 2 \
  "yes" " " \
  "no" " " 3>&2 2>&1 1>&3)

case $CHOICE in
  yes)
    set +e
    NEW_CRONTAB_COMMAND="(sleep 60 && echo \"$current_governor\" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor)"
    EXISTING_CRONTAB=$(crontab -l 2>/dev/null)
    if [[ -n "$EXISTING_CRONTAB" ]]; then
      TEMP_CRONTAB_FILE=$(mktemp)
      echo "$EXISTING_CRONTAB" | grep -v "@reboot (sleep 60 && echo*" > "$TEMP_CRONTAB_FILE"
      crontab "$TEMP_CRONTAB_FILE"
      rm "$TEMP_CRONTAB_FILE"
    fi
    (crontab -l 2>/dev/null; echo "@reboot $NEW_CRONTAB_COMMAND") | crontab -
    echo -e "\nCrontab Set (use 'crontab -e' to check)"
    ;;
  no)
    echo -e "\n\033[31mNOTE: Settings return to default after reboot\033[m\n"
    ;;
esac
echo -e "Current CPU Scaling Governor is set to \033[36m$current_governor\033[m\n"
