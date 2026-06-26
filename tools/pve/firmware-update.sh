#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    _______                                      __  __          __      __
   / ____(_)________ _      ______ _________     / / / /___  ____/ /___ _/ /____
  / /_  / / ___/ __ `/ | /| / / __ `/ ___/ _ \   / / / / __ \/ __  / __ `/ __/ _ \
 / __/ / / /  / /_/ /| |/ |/ / /_/ / /  /  __/  / /_/ / /_/ / /_/ / /_/ / /_/  __/
/_/   /_/_/   \__,_/ |__/|__/\__,_/_/   \___/   \____/ .___/\__,_/\__,_/\__/\___/
                                                    /_/
EOF
}

# Color variables
YW="\033[33m"
GN="\033[1;92m"
RD="\033[01;31m"
CL="\033[m"
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

msg_info() { echo -ne " ${HOLD} ${YW}$1..."; }
msg_ok() { echo -e "${BFR} ${CM} ${GN}$1${CL}"; }
msg_error() { echo -e "${BFR} ${CROSS} ${RD}$1${CL}"; }

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "firmware-update" "pve"

header_info

# Must run as root
if [ "$(id -u)" -ne 0 ]; then
  msg_error "This script must be run as root."
  exit 1
fi

# Must run on Proxmox VE 8.x or 9.x
if ! command -v pveversion >/dev/null 2>&1; then
  msg_error "No Proxmox VE detected!"
  exit 1
fi
if ! pveversion | grep -Eq "pve-manager/(8\.[0-4]|9\.[0-9]+)(\.[0-9]+)*"; then
  msg_error "This version of Proxmox Virtual Environment is not supported."
  msg_error "Requires Proxmox Virtual Environment Version 8.0-8.4 or 9.x."
  exit 1
fi

# Firmware updates only make sense on bare metal
virt=$(systemd-detect-virt 2>/dev/null || echo "none")
if [ "$virt" != "none" ]; then
  msg_error "Firmware updates can only be applied on bare metal. Detected: $virt"
  exit 1
fi

# Only x86_64/arm64 with UEFI/LVFS support; fwupd itself handles capability checks
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Firmware Update (fwupd / LVFS)" \
  --yesno "This tool uses fwupd to check for and optionally install firmware updates (UEFI/BIOS and supported devices) from the Linux Vendor Firmware Service (LVFS).\n\nWARNING: Flashing firmware carries risk. Ensure stable power and do not interrupt the process. Some updates require a reboot to be applied.\n\nProceed?" 16 70 || exit 0

# Install fwupd if missing
if ! command -v fwupdmgr >/dev/null 2>&1; then
  msg_info "Installing fwupd"
  apt-get update &>/dev/null
  if ! apt-get install -y fwupd &>/dev/null; then
    msg_error "Failed to install fwupd"
    exit 1
  fi
  msg_ok "Installed fwupd"
else
  msg_ok "fwupd is already installed"
fi

# Refresh metadata from LVFS
msg_info "Refreshing firmware metadata from LVFS"
if fwupdmgr refresh --force &>/dev/null; then
  msg_ok "Refreshed firmware metadata"
else
  # A failed refresh is not fatal (cached metadata may still be usable)
  msg_error "Could not refresh metadata (continuing with cached data)"
fi

# Show detected, updatable devices
echo -e "\n${YW}Detected devices with firmware management support:${CL}\n"
fwupdmgr get-devices --no-unreported-check 2>/dev/null || true
echo

# Check for available updates
msg_info "Checking for available firmware updates"
updates_output=$(fwupdmgr get-updates --no-unreported-check 2>&1)
updates_rc=$?
msg_ok "Checked for firmware updates"

if [ "$updates_rc" -ne 0 ] || echo "$updates_output" | grep -qiE "No (updates|upgrades) available|Devices with no available firmware updates"; then
  echo -e "\n$updates_output\n"
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "No Firmware Updates" \
    --msgbox "No applicable firmware updates were found for this system." 10 68
  echo -e "${GN}Nothing to do.${CL}"
  exit 0
fi

echo -e "\n${YW}Available firmware updates:${CL}\n"
echo "$updates_output"
echo

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Apply Firmware Updates" \
  --yesno "Firmware updates are available (see terminal output).\n\nDo you want to apply them now?\n\nNOTE: Some updates schedule a flash on the next reboot. Do NOT power off during the process." 14 70 || {
  echo -e "${YW}Skipped applying updates.${CL}"
  exit 0
}

msg_info "Applying firmware updates (this may take a while)"
echo
if fwupdmgr update -y; then
  msg_ok "Firmware update process completed"
  echo -e "\n${YW}A reboot may be required to finalize some firmware updates.${CL}\n"
else
  msg_error "Firmware update reported an error. Review the output above."
  exit 1
fi
