#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____                                               __  ____                                __
   / __ \_________  ________  ______________  _____   /  |/  (_)_____________  _________  ____/ /__
  / /_/ / ___/ __ \/ ___/ _ \/ ___/ ___/ __ \/ ___/  / /|_/ / / ___/ ___/ __ \/ ___/ __ \/ __  / _ \
 / ____/ /  / /_/ / /__/  __(__  |__  ) /_/ / /     / /  / / / /__/ /  / /_/ / /__/ /_/ / /_/ /  __/
/_/   /_/   \____/\___/\___/____/____/\____/_/     /_/  /_/_/\___/_/   \____/\___/\____/\__,_/\___/

EOF
}

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

  intel_microcode=$(curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode//" | grep -o 'href="[^"]*amd64.deb"' | sed 's/href="//;s/"//')
  [ -z "$intel_microcode" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "No Microcode Found" --msgbox "It appears there were no microcode packages found\n Try again later." 10 68
    msg_info "Exiting"
    sleep 1
    msg_ok "Done"
    exit
  }

  MICROCODE_MENU=()
  MSG_MAX_LENGTH=0

  while read -r TAG ITEM; do
    OFFSET=2
    ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
    MICROCODE_MENU+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$intel_microcode")

  microcode=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Current Microcode revision:${current_microcode}" --radiolist "\nSelect a microcode package to install:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${MICROCODE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

  [ -z "$microcode" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "No Microcode Selected" --msgbox "It appears that no microcode packages were selected" 10 68
    msg_info "Exiting"
    sleep 1
    msg_ok "Done"
    exit
  }

  msg_info "Downloading the Intel Processor Microcode Package $microcode"
  curl -fsSL "http://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode/$microcode" -o $(basename "http://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode/$microcode")
  msg_ok "Downloaded the Intel Processor Microcode Package $microcode"

  msg_info "Installing $microcode (Patience)"
  dpkg -i $microcode &>/dev/null
  msg_ok "Installed $microcode"

  msg_info "Cleaning up"
  rm $microcode
  msg_ok "Cleaned"
  echo -e "\nIn order to apply the changes, a system reboot will be necessary.\n"
}

amd() {
  amd_microcode=$(curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode///" | grep -o 'href="[^"]*amd64.deb"' | sed 's/href="//;s/"//')

  [ -z "$amd_microcode" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "No Microcode Found" --msgbox "It appears there were no microcode packages found\n Try again later." 10 68
    msg_info "Exiting"
    sleep 1
    msg_ok "Done"
    exit
  }

  MICROCODE_MENU=()
  MSG_MAX_LENGTH=0

  while read -r TAG ITEM; do
    OFFSET=2
    ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
    MICROCODE_MENU+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$amd_microcode")

  microcode=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Current Microcode revision:${current_microcode}" --radiolist "\nSelect a microcode package to install:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${MICROCODE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

  [ -z "$microcode" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "No Microcode Selected" --msgbox "It appears that no microcode packages were selected" 10 68
    msg_info "Exiting"
    sleep 1
    msg_ok "Done"
    exit
  }

  msg_info "Downloading the AMD Processor Microcode Package $microcode"
  curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode/$microcode" -o $(basename "https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode/$microcode")
  msg_ok "Downloaded the AMD Processor Microcode Package $microcode"

  msg_info "Installing $microcode (Patience)"
  dpkg -i $microcode &>/dev/null
  msg_ok "Installed $microcode"

  msg_info "Cleaning up"
  rm $microcode
  msg_ok "Cleaned"
  echo -e "\nIn order to apply the changes, a system reboot will be necessary.\n"
}

if ! command -v pveversion >/dev/null 2>&1; then
  header_info
  msg_error "No PVE Detected!"
  exit
fi

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Processor Microcode" --yesno "This will check for CPU microcode packages with the option to install. Proceed?" 10 58

msg_info "Checking CPU Vendor"
cpu=$(lscpu | grep -oP 'Vendor ID:\s*\K\S+' | head -n 1)
if [ "$cpu" == "GenuineIntel" ]; then
  msg_ok "${cpu} was detected"
  sleep 1
  intel
elif [ "$cpu" == "AuthenticAMD" ]; then
  msg_ok "${cpu} was detected"
  sleep 1
  amd
else
  msg_error "${cpu} is not supported"
  exit
fi
