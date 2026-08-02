#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
set -e

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "scaling-governor" "pve"

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
whiptail --backtitle "Proxmox VE Helper Scripts" --title "CPU Scaling Governors" --yesno "View/Change CPU Scaling Governors. Proceed?" 10 58 || exit 0

GOV_BASE="/sys/devices/system/cpu/cpu0/cpufreq"
if [[ ! -r "$GOV_BASE/scaling_governor" || ! -r "$GOV_BASE/scaling_available_governors" ]]; then
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "CPU Scaling Not Available" \
    --msgbox "CPU frequency scaling is not available on this system.\n\nThis is normal when no cpufreq driver is active (e.g. CPU power management handled by the BIOS, or certain virtualized hosts)." 12 70
  clear
  exit 0
fi

current_governor=$(cat "$GOV_BASE/scaling_governor")
GOVERNORS_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  GOVERNORS_MENU+=("$TAG" "$ITEM " "OFF")
done < <(tr ' ' '\n' <"$GOV_BASE/scaling_available_governors" | sed '/^$/d' | grep -vxF "$current_governor")
# A radiolist is used on purpose: only a single governor can be active at a time.
scaling_governor=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Current CPU Scaling Governor is set to $current_governor" --radiolist "\nSelect the Scaling Governor to use:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${GOVERNORS_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')
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
    echo "$EXISTING_CRONTAB" | grep -vF "@reboot (sleep 60 && echo" >"$TEMP_CRONTAB_FILE"
    crontab "$TEMP_CRONTAB_FILE"
    rm "$TEMP_CRONTAB_FILE"
  fi
  (
    crontab -l 2>/dev/null
    echo "@reboot $NEW_CRONTAB_COMMAND"
  ) | crontab -
  echo -e "\nCrontab Set (use 'crontab -e' to check)"
  ;;
no)
  echo -e "\n\033[31mNOTE: Settings return to default after reboot\033[m\n"
  ;;
esac
echo -e "Current CPU Scaling Governor is set to \033[36m$current_governor\033[m\n"
