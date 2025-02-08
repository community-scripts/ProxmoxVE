#!/usr/bin/env bash
# Copyright (c) 2021-2025 tteck
# Copyright (c) 2025 DonPablo1010
# Adapted for the Proxmox Backup Server - Baremetal Only
# License: MIT
# This script searches for CPU microcode packages (Intel/AMD) and offers the option to install them.
# A system reboot is required to apply the changes.
# IMPORTANT: This script will only proceed if running on bare metal. If running in a VM, it will exit.

function header_info {
  clear
  cat <<"EOF"
    ____                                               __  ____                                __
   / __ \_________  ________  ______________  _____   /  |/  (_)_____________  _________  ____/ /__
  / /_/ / ___/ __ \/ ___/ _ \/ ___/ ___/ __ \/ ___/  / /|_/ / / ___/ ___/ __ \/ ___/ __ \/ __  / _ \
 / ____/ /  / /_/ / /__/  __(__  |__  ) /_/ / /     / /  / / / /__/ /  / /_/ / /__/ /_/ / /_/ /  __/
/_/   /_/   \____/\___/\___/____/____/\____/_/     /_/  /_/_/\___/_/   \____/\___/\____/\__,_/\___/

              Proxmox Backup Server Processor Microcode Updater
EOF
}

# Color definitions
RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

msg_info() { echo -ne " ${HOLD} ${YW}$1..."; }
msg_ok() { echo -e "${BFR} ${CM} ${GN}$1${CL}"; }
msg_error() { echo -e "${BFR} ${CROSS} ${RD}$1${CL}"; }

header_info

# Check if running on bare metal using systemd-detect-virt.
virt=$(systemd-detect-virt)
if [ "$virt" != "none" ]; then
    msg_error "This script must be run on bare metal. Detected virtual environment: $virt"
    exit 1
fi

# Attempt to obtain the current loaded microcode revision
current_microcode=$(journalctl -k | grep -i 'microcode: Current revision:' | grep -oP 'Current revision: \K0x[0-9a-f]+')
[ -z "$current_microcode" ] && current_microcode="Not found."

intel() {
  if ! dpkg -s iucode-tool >/dev/null 2>&1; then
    msg_info "Installing iucode-tool (Intel microcode updater)"
    apt-get install -y iucode-tool &>/dev/null
    msg_ok "Installed iucode-tool"
  else
    msg_ok "Intel iucode-tool is already installed"
    sleep 1
  fi

  intel_microcode=$(curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode/" | grep -o 'href="[^"]*amd64.deb"' | sed 's/href="//;s/"//')
  [ -z "$intel_microcode" ] && { 
    whiptail --backtitle "Proxmox Backup Server Helper Scripts" --title "No Microcode Found" --msgbox "No microcode packages were found.\nTry again later." 10 68
    msg_info "Exiting"
    sleep 1
    msg_ok "Done"
    exit
  }

  MICROCODE_MENU=()
  MSG_MAX_LENGTH=0

  while read -r TAG ITEM; do
    OFFSET=2
    (( ${#ITEM} + OFFSET > MSG_MAX_LENGTH )) && MSG_MAX_LENGTH=$(( ${#ITEM} + OFFSET ))
    MICROCODE_MENU+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$intel_microcode")

  microcode=$(whiptail --backtitle "Proxmox Backup Server Helper Scripts" \
    --title "Current Microcode Revision: ${current_microcode}" \
    --radiolist "\nSelect a microcode package to install:\n" \
    16 $((MSG_MAX_LENGTH + 58)) 6 "${MICROCODE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

  [ -z "$microcode" ] && { 
    whiptail --backtitle "Proxmox Backup Server Helper Scripts" --title "No Microcode Selected" --msgbox "No microcode package was selected." 10 68
    msg_info "Exiting"
    sleep 1
    msg_ok "Done"
    exit
  }

  msg_info "Downloading Intel processor microcode package $microcode"
  wget -q http://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode/$microcode
  msg_ok "Downloaded Intel processor microcode package $microcode"

  msg_info "Installing $microcode (this might take a while)"
  dpkg -i $microcode &>/dev/null
  msg_ok "Installed $microcode"

  msg_info "Cleaning up"
  rm $microcode
  msg_ok "Clean up complete"
  echo -e "\nA system reboot is required to apply the changes.\n"
}

amd() {
  amd_microcode=$(curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode/" | grep -o 'href="[^"]*amd64.deb"' | sed 's/href="//;s/"//')

  [ -z "$amd_microcode" ] && { 
    whiptail --backtitle "Proxmox Backup Server Helper Scripts" --title "No Microcode Found" --msgbox "No microcode packages were found.\nTry again later." 10 68
    msg_info "Exiting"
    sleep 1
    msg_ok "Done"
    exit
  }

  MICROCODE_MENU=()
  MSG_MAX_LENGTH=0

  while read -r TAG ITEM; do
    OFFSET=2
    (( ${#ITEM} + OFFSET > MSG_MAX_LENGTH )) && MSG_MAX_LENGTH=$(( ${#ITEM} + OFFSET ))
    MICROCODE_MENU+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$amd_microcode")

  microcode=$(whiptail --backtitle "Proxmox Backup Server Helper Scripts" \
    --title "Current Microcode Revision: ${current_microcode}" \
    --radiolist "\nSelect a microcode package to install:\n" \
    16 $((MSG_MAX_LENGTH + 58)) 6 "${MICROCODE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

  [ -z "$microcode" ] && { 
    whiptail --backtitle "Proxmox Backup Server Helper Scripts" --title "No Microcode Selected" --msgbox "No microcode package was selected." 10 68
    msg_info "Exiting"
    sleep 1
    msg_ok "Done"
    exit
  }

  msg_info "Downloading AMD processor microcode package $microcode"
  wget -q https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode/$microcode
  msg_ok "Downloaded AMD processor microcode package $microcode"

  msg_info "Installing $microcode (this might take a while)"
  dpkg -i $microcode &>/dev/null
  msg_ok "Installed $microcode"

  msg_info "Cleaning up"
  rm $microcode
  msg_ok "Clean up complete"
  echo -e "\nA system reboot is required to apply the changes.\n"
}

# Check if this is a Proxmox Backup Server by verifying the presence of the datastore config.
if [ ! -f /etc/proxmox-backup/datastore.cfg ]; then
  header_info
  msg_error "Proxmox Backup Server not detected!"
  exit
fi

whiptail --backtitle "Proxmox Backup Server Helper Scripts" \
  --title "Proxmox Backup Server Processor Microcode" \
  --yesno "This script searches for CPU microcode packages and offers the option to install them.\nProceed?" 10 68 || exit

msg_info "Checking CPU vendor"
cpu=$(lscpu | grep -oP 'Vendor ID:\s*\K\S+' | head -n 1)
if [ "$cpu" == "GenuineIntel" ]; then
  msg_ok "${cpu} detected"
  sleep 1
  intel
elif [ "$cpu" == "AuthenticAMD" ]; then
  msg_ok "${cpu} detected"
  sleep 1
  amd
else
  msg_error "CPU vendor ${cpu} is not supported"
  exit
fi
