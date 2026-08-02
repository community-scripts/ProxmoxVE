#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
load_functions
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "disk-health" "pve"

function header_info {
  clear
  cat <<"EOF"
    ____  _      __      __  __           ____  __
   / __ \(_)____/ /__   / / / /__  ____ _/ / /_/ /_
  / / / / / ___/ //_/  / /_/ / _ \/ __ `/ / __/ __ \
 / /_/ / (__  ) ,<    / __  /  __/ /_/ / / /_/ / / /
/_____/_/____/_/|_|  /_/ /_/\___/\__,_/_/\__/_/ /_/

EOF
}

header_info

# Must run as root (SMART access requires it)
if [ "$(id -u)" -ne 0 ]; then
  msg_error "This script must be run as root."
  exit 1
fi

if ! command -v pveversion >/dev/null 2>&1; then
  msg_error "No Proxmox VE detected!"
  exit 1
fi

# Install required tooling on demand
if ! command -v smartctl >/dev/null 2>&1; then
  msg_info "Installing smartmontools"
  apt-get update &>/dev/null
  if apt-get install -y smartmontools &>/dev/null; then
    msg_ok "Installed smartmontools"
  else
    msg_error "Failed to install smartmontools"
    exit 1
  fi
fi
if ! command -v nvme >/dev/null 2>&1; then
  msg_info "Installing nvme-cli"
  if apt-get install -y nvme-cli &>/dev/null; then
    msg_ok "Installed nvme-cli"
  else
    msg_error "nvme-cli not available (NVMe details limited)"
  fi
fi

# Collect physical disks (exclude loop, zram and device-mapper devices)
mapfile -t DISKS < <(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}' | grep -vE '^(loop|zram|dm-)' | sort)

if [ "${#DISKS[@]}" -eq 0 ]; then
  msg_error "No physical disks found."
  exit 0
fi

# Pull a single attribute value out of "smartctl -A" output by attribute name
sata_attr() {
  local output="$1" name="$2"
  echo "$output" | awk -v n="$name" '$2==n {print $10; exit}'
}

report_disk() {
  local dev="$1"
  local path="/dev/${dev}"
  local model size health
  model=$(lsblk -dn -o MODEL "$path" 2>/dev/null | sed 's/[[:space:]]*$//')
  size=$(lsblk -dn -o SIZE "$path" 2>/dev/null | tr -d ' ')

  echo -e "\n${BL}======================================================${CL}"
  echo -e "${GN}${path}${CL}  ${YW}${size:-?}${CL}  ${model:-Unknown model}"
  echo -e "${BL}======================================================${CL}"

  # Overall SMART health verdict
  health=$(smartctl -H "$path" 2>/dev/null | grep -iE "SMART overall-health|SMART Health Status" | sed 's/.*: *//')
  if [ -z "$health" ]; then
    echo -e "  Health: ${YW}SMART not available for this device${CL}"
  elif echo "$health" | grep -qiE "PASSED|OK"; then
    echo -e "  Health: ${GN}${health}${CL}"
  else
    echo -e "  Health: ${RD}${health}${CL}"
  fi

  if [[ "$dev" == nvme* ]]; then
    local a
    a=$(smartctl -A "$path" 2>/dev/null)
    echo "$a" | grep -iE "Temperature:|Available Spare:|Percentage Used:|Data Units Written:|Power On Hours:|Unsafe Shutdowns:|Media and Data Integrity Errors:" |
      sed 's/^/  /'
  else
    local a poh temp realloc pending offline crc wear
    a=$(smartctl -A "$path" 2>/dev/null)
    poh=$(sata_attr "$a" "Power_On_Hours")
    temp=$(sata_attr "$a" "Temperature_Celsius")
    realloc=$(sata_attr "$a" "Reallocated_Sector_Ct")
    pending=$(sata_attr "$a" "Current_Pending_Sector")
    offline=$(sata_attr "$a" "Offline_Uncorrectable")
    crc=$(sata_attr "$a" "UDMA_CRC_Error_Count")
    wear=$(sata_attr "$a" "Wear_Leveling_Count")
    [ -z "$wear" ] && wear=$(sata_attr "$a" "Media_Wearout_Indicator")

    [ -n "$temp" ] && echo -e "  Temperature:           ${temp} C"
    [ -n "$poh" ] && echo -e "  Power On Hours:        ${poh}"
    [ -n "$wear" ] && echo -e "  Wear Leveling/Wearout: ${wear}"
    print_attr() {
      local label="$1" val="$2"
      [ -z "$val" ] && return
      if [ "$val" -gt 0 ] 2>/dev/null; then
        echo -e "  ${label} ${RD}${val}${CL}"
      else
        echo -e "  ${label} ${GN}${val}${CL}"
      fi
    }
    print_attr "Reallocated Sectors:  " "$realloc"
    print_attr "Pending Sectors:      " "$pending"
    print_attr "Offline Uncorrectable:" "$offline"
    print_attr "UDMA CRC Errors:      " "$crc"
  fi
}

header_info
echo -e "${YW}Scanning ${#DISKS[@]} disk(s) for SMART health...${CL}"
for d in "${DISKS[@]}"; do
  report_disk "$d"
done
echo

# Offer an optional, non-destructive short self-test
if whiptail --backtitle "Proxmox VE Helper Scripts" --title "SMART Self-Test" \
  --yesno "Health report complete.\n\nDo you want to start a non-destructive SHORT SMART self-test on a disk?\n\n(The test runs in the background; check results later with: smartctl -a /dev/XXX)" 14 70; then
  TEST_MENU=()
  for d in "${DISKS[@]}"; do
    TEST_MENU+=("$d" "/dev/$d" "OFF")
  done
  sel=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Select Disk for Short Self-Test" \
    --radiolist "\nSelect a disk:\n" 16 60 6 "${TEST_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')
  if [ -n "$sel" ]; then
    msg_info "Starting short self-test on /dev/$sel"
    if smartctl -t short "/dev/$sel" &>/dev/null; then
      msg_ok "Short self-test started on /dev/$sel"
      echo -e "${YW}Check progress/result with: ${GN}smartctl -a /dev/$sel${CL}"
    else
      msg_error "Could not start self-test on /dev/$sel"
    fi
  fi
fi

echo -e "\n${GN}Disk health check complete.${CL}\n"
