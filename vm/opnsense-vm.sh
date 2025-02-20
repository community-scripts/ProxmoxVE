#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<$(wget -qLO - https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func)

function header_info {
  clear
  cat <<"EOF" 
   ____  ____  _   __                        
  / __ \/ __ \/ | / /_______  ____  ________ 
 / / / / /_/ /  |/ / ___/ _ \/ __ \/ ___/ _ \
/ /_/ / ____/ /|  (__  )  __/ / / (__  )  __/
\____/_/   /_/ |_/____/\___/_/ /_/____/\___/ 
                                                                         
EOF
}
header_info
echo -e "Loading..."
#API VARIABLES
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
NSAPP="opnsense-vm"
var_os="opnsense"
var_version="25.1"
#
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
GEN_MAC_LAN=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
NEXTID=$(pvesh get /cluster/nextid)
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
HA=$(echo "\033[1;34m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
set -Eeo pipefail
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  post_update_to_api "failed" "$command"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
  cleanup_vmid
}

function cleanup_vmid() {
  if qm status $VMID &>/dev/null; then
    qm stop $VMID &>/dev/null
    qm destroy $VMID &>/dev/null
  fi
}

function cleanup() {
  popd >/dev/null
  post_update_to_api "done" "none"
  rm -rf $TEMP_DIR
}

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null
function send_line_to_vm() {
  echo -e "${DGN}Sending line: ${YW}$1${CL}"
  for ((i = 0; i < ${#1}; i++)); do
    character=${1:i:1}
    case $character in
    " ") character="spc" ;;
    "-") character="minus" ;;
    "=") character="equal" ;;
    ",") character="comma" ;;
    ".") character="dot" ;;
    "/") character="slash" ;;
    "'") character="apostrophe" ;;
    ";") character="semicolon" ;;
    '\') character="backslash" ;;
    '`') character="grave_accent" ;;
    "[") character="bracket_left" ;;
    "]") character="bracket_right" ;;
    "_") character="shift-minus" ;;
    "+") character="shift-equal" ;;
    "?") character="shift-slash" ;;
    "<") character="shift-comma" ;;
    ">") character="shift-dot" ;;
    '"') character="shift-apostrophe" ;;
    ":") character="shift-semicolon" ;;
    "|") character="shift-backslash" ;;
    "~") character="shift-grave_accent" ;;
    "{") character="shift-bracket_left" ;;
    "}") character="shift-bracket_right" ;;
    "A") character="shift-a" ;;
    "B") character="shift-b" ;;
    "C") character="shift-c" ;;
    "D") character="shift-d" ;;
    "E") character="shift-e" ;;
    "F") character="shift-f" ;;
    "G") character="shift-g" ;;
    "H") character="shift-h" ;;
    "I") character="shift-i" ;;
    "J") character="shift-j" ;;
    "K") character="shift-k" ;;
    "L") character="shift-l" ;;
    "M") character="shift-m" ;;
    "N") character="shift-n" ;;
    "O") character="shift-o" ;;
    "P") character="shift-p" ;;
    "Q") character="shift-q" ;;
    "R") character="shift-r" ;;
    "S") character="shift-s" ;;
    "T") character="shift-t" ;;
    "U") character="shift-u" ;;
    "V") character="shift-v" ;;
    "W") character="shift-w" ;;
    "X") character="shift=x" ;;
    "Y") character="shift-y" ;;
    "Z") character="shift-z" ;;
    "!") character="shift-1" ;;
    "@") character="shift-2" ;;
    "#") character="shift-3" ;;
    '$') character="shift-4" ;;
    "%") character="shift-5" ;;
    "^") character="shift-6" ;;
    "&") character="shift-7" ;;
    "*") character="shift-8" ;;
    "(") character="shift-9" ;;
    ")") character="shift-0" ;;
    esac
    qm sendkey $VMID "$character"
  done
  qm sendkey $VMID ret
}

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "OPNsense VM" --yesno "This will create a New OPNsense VM. Proceed?" 10 58); then
  :
else
  header_info && echo -e "⚠ User exited script \n" && exit
fi

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

function msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

function pve_check() {
  if ! pveversion | grep -Eq "pve-manager/8.[1-3]"; then
    msg_error "This version of Proxmox Virtual Environment is not supported"
    echo -e "Requires Proxmox Virtual Environment Version 8.1 or later."
    echo -e "Exiting..."
    sleep 2
    exit
  fi
}

function arch_check() {
  if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    echo -e "\n ${CROSS} This script will not work with PiMox! \n"
    echo -e "Exiting..."
    sleep 2
    exit
  fi
}

function ssh_check() {
  if command -v pveversion >/dev/null 2>&1; then
    if [ -n "${SSH_CLIENT:+x}" ]; then
      if whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "SSH DETECTED" --yesno "It's suggested to use the Proxmox shell instead of SSH, since SSH can create issues while gathering variables. Would you like to proceed with using SSH?" 10 62; then
        echo "you've been warned"
      else
        clear
        exit
      fi
    fi
  fi
}

function exit-script() {
  clear
  echo -e "⚠  User exited script \n"
  exit
}

function default_settings() {
  VMID="$NEXTID"
  FORMAT=",efitype=4m"
  MACHINE=""
  DISK_CACHE=""
  HN="opnsense"
  CPU_TYPE=""
  CORE_COUNT="4"
  RAM_SIZE="8192"
  BRG="vmbr0"
  IP_ADDR=""
  WAN_IP_ADDR=""
  LAN_GW=""
  WAN_GW=""
  NETMASK=""
  WAN_NETMASK=""
  VLAN=""
  MAC=$GEN_MAC
  WAN_MAC=$GEN_MAC_LAN
  WAN_BRG="vmbr1"
  MTU=""
  START_VM="yes"
  METHOD="default"

  echo -e "${DGN}Using Virtual Machine ID: ${BGN}${VMID}${CL}"
  echo -e "${DGN}Using Hostname: ${BGN}${HN}${CL}"
  echo -e "${DGN}Allocated Cores: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${DGN}Allocated RAM: ${BGN}${RAM_SIZE}${CL}"
  if ! grep -q "^iface ${BRG}" /etc/network/interfaces; then
  msg_error "Bridge '${BRG}' does not exist in /etc/network/interfaces"
  exit
  else
    echo -e "${DGN}Using LAN Bridge: ${BGN}${BRG}${CL}"
  fi
  echo -e "${DGN}Using LAN VLAN: ${BGN}Default${CL}"
  echo -e "${DGN}Using LAN MAC Address: ${BGN}${MAC}${CL}"
  echo -e "${DGN}Using WAN MAC Address: ${BGN}${WAN_MAC}${CL}"
  if ! grep -q "^iface ${WAN_BRG}" /etc/network/interfaces; then
    msg_error "Bridge '${WAN_BRG}' does not exist in /etc/network/interfaces"
    exit
  else
    echo -e "${DGN}Using WAN Bridge: ${BGN}${WAN_BRG}${CL}"
  fi
  echo -e "${DGN}Using Interface MTU Size: ${BGN}Default${CL}"
  echo -e "${DGN}Start VM when completed: ${BGN}yes${CL}"
  echo -e "${BL}Creating a OPNsense VM using the above default settings${CL}"
}

function advanced_settings() {
  local ip_regex='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'
  METHOD="advanced"
  while true; do
    if VMID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Virtual Machine ID" 8 58 $NEXTID --title "VIRTUAL MACHINE ID" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
      if [ -z "$VMID" ]; then
        VMID="$NEXTID"
      fi
      if pct status "$VMID" &>/dev/null || qm status "$VMID" &>/dev/null; then
        echo -e "${CROSS}${RD} ID $VMID is already in use${CL}"
        sleep 2
        continue
      fi
      echo -e "${DGN}Virtual Machine ID: ${BGN}$VMID${CL}"
      break
    else
      exit-script
    fi
  done

  if MACH=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "MACHINE TYPE" --radiolist --cancel-button Exit-Script "Choose Type" 10 58 2 \
    "i440fx" "Machine i440fx" ON \
    "q35" "Machine q35" OFF \
    3>&1 1>&2 2>&3); then
    if [ $MACH = q35 ]; then
      echo -e "${DGN}Using Machine Type: ${BGN}$MACH${CL}"
      FORMAT=""
      MACHINE=" -machine q35"
    else
      echo -e "${DGN}Using Machine Type: ${BGN}$MACH${CL}"
      FORMAT=",efitype=4m"
      MACHINE=""
    fi
  else
    exit-script
  fi

  if CPU_TYPE1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CPU MODEL" --radiolist "Choose" --cancel-button Exit-Script 10 58 2 \
    "0" "KVM64 (Default)" ON \
    "1" "Host" OFF \
    3>&1 1>&2 2>&3); then
    if [ $CPU_TYPE1 = "1" ]; then
      echo -e "${DGN}Using CPU Model: ${BGN}Host${CL}"
      CPU_TYPE=" -cpu host"
    else
      echo -e "${DGN}Using CPU Model: ${BGN}KVM64${CL}"
      CPU_TYPE=""
    fi
  else
    exit-script
  fi

  if DISK_CACHE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "DISK CACHE" --radiolist "Choose" --cancel-button Exit-Script 10 58 2 \
    "0" "None (Default)" ON \
    "1" "Write Through" OFF \
    3>&1 1>&2 2>&3); then
    if [ $DISK_CACHE = "1" ]; then
      echo -e "${DGN}Using Disk Cache: ${BGN}Write Through${CL}"
      DISK_CACHE="cache=writethrough,"
    else
      echo -e "${DGN}Using Disk Cache: ${BGN}None${CL}"
      DISK_CACHE=""
    fi
  else
    exit-script
  fi

  if VM_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Hostname" 8 58 OPNsense --title "HOSTNAME" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $VM_NAME ]; then
      HN="OPNsense"
    else
      HN=$(echo ${VM_NAME,,} | tr -d ' ')
    fi
    echo -e "${DGN}Using Hostname: ${BGN}$HN${CL}"
  else
    exit-script
  fi

  if CORE_COUNT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores" 8 58 4 --title "CORE COUNT" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $CORE_COUNT ]; then
      CORE_COUNT="2"
    fi
    echo -e "${DGN}Allocated Cores: ${BGN}$CORE_COUNT${CL}"
  else
    exit-script
  fi

  if RAM_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in MiB" 8 58 8192 --title "RAM" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $RAM_SIZE ]; then
      RAM_SIZE="8192"
    fi
    echo -e "${DGN}Allocated RAM: ${BGN}$RAM_SIZE${CL}"
  else
    exit-script
  fi

  if BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a LAN Bridge" 8 58 vmbr0 --title "LAN BRIDGE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $BRG ]; then
      BRG="vmbr0"
    fi
    if ! grep -q "^iface ${BRG}" /etc/network/interfaces; then
      msg_error "Bridge '${BRG}' does not exist in /etc/network/interfaces"
      exit
    fi
    echo -e "${DGN}Using LAN Bridge: ${BGN}$BRG${CL}"
  else
    exit-script
  fi

  if IP_ADDR=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a LAN IP" 8 58 $IP_ADDR --title "LAN IP ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $IP_ADDR ]; then
      echo -e "${DGN}Using DHCP AS LAN IP ADDRESS${CL}"
    else
      if [[ -n "$IP_ADDR" && ! "$IP_ADDR" =~ $ip_regex ]]; then
        msg_error "Invalid IP Address format for LAN IP. Needs to be 0.0.0.0, was $IP_ADDR"
        exit
      fi
      echo -e "${DGN}Using LAN IP ADDRESS: ${BGN}$IP_ADDR${CL}"
      if LAN_GW=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a LAN GATEWAY IP" 8 58 $LAN_GW --title "LAN GATEWAY IP ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
        if [ -z $LAN_GW ]; then
          echo -e "${DGN}Gateway needs to be set if ip is not dhcp${CL}"
          exit-script
        fi
        if [[ -n "$LAN_GW" && ! "$LAN_GW" =~ $ip_regex ]]; then
          msg_error "Invalid IP Address format for Gateway. Needs to be 0.0.0.0, was $LAN_GW"
          exit
        fi
        echo -e "${DGN}Using LAN GATEWAY ADDRESS: ${BGN}$LAN_GW${CL}"
      fi
      if NETMASK=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a LAN netmmask (24 for example)" 8 58 $NETMASK --title "LAN NETMASK" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
        if [ -z $NETMASK ]; then
          echo -e "${DGN}Netmask needs to be set if ip is not dhcp${CL}"
        fi
        if [[ -n "$NETMASK" && ! ("$NETMASK" =~ ^[0-9]+$ && "$NETMASK" -ge 1 && "$NETMASK" -le 32) ]]; then
          msg_error "Invalid LAN NETMASK format. Needs to be 1-32, was $NETMASK"
          exit
        fi
        echo -e "${DGN}Using LAN NETMASK: ${BGN}$NETMASK${CL}"
      else
        exit-script
      fi
    fi
  else
    exit-script
  fi

  if WAN_BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a WAN Bridge" 8 58 vmbr1 --title "WAN BRIDGE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $WAN_BRG ]; then
      WAN_BRG="vmbr1"
    fi
    if ! grep -q "^iface ${WAN_BRG}" /etc/network/interfaces; then
      msg_error "WAN Bridge '${WAN_BRG}' does not exist in /etc/network/interfaces"
      exit
    fi
    echo -e "${DGN}Using WAN Bridge: ${BGN}$WAN_BRG${CL}"
  else
    exit-script
  fi

  if WAN_IP_ADDR=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a WAN IP" 8 58 $WAN_IP_ADDR --title "WAN IP ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $WAN_IP_ADDR ]; then
      echo -e "${DGN}Using DHCP AS WAN IP ADDRESS${CL}"
    else
      if [[ -n "$WAN_IP_ADDR" && ! "$WAN_IP_ADDR" =~ $ip_regex ]]; then
        msg_error "Invalid IP Address format for WAN IP. Needs to be 0.0.0.0, was $WAN_IP_ADDR"
        exit
      fi
      echo -e "${DGN}Using WAN IP ADDRESS: ${BGN}$WAN_IP_ADDR${CL}"
      if WAN_GW=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a WAN GATEWAY IP" 8 58 $WAN_GW --title "WAN GATEWAY IP ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
        if [ -z $WAN_GW ]; then
          echo -e "${DGN}Gateway needs to be set if ip is not dhcp${CL}"
          exit-script
        fi
        if [[ -n "$WAN_GW" && ! "$WAN_GW" =~ $ip_regex ]]; then
          msg_error "Invalid IP Address format for WAN Gateway. Needs to be 0.0.0.0, was $WAN_GW"
          exit
        fi
        echo -e "${DGN}Using WAN GATEWAY ADDRESS: ${BGN}$WAN_GW${CL}"
      else
        exit-script
      fi
      if WAN_NETMASK=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a WAN netmmask (24 for example)" 8 58 $WAN_NETMASK --title "WAN NETMASK" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
        if [ -z $WAN_NETMASK ]; then
          echo -e "${DGN}WAN Netmask needs to be set if ip is not dhcp${CL}"
        fi
        if [[ -n "$WAN_NETMASK" && ! ("$WAN_NETMASK" =~ ^[0-9]+$ && "$WAN_NETMASK" -ge 1 && "$WAN_NETMASK" -le 32) ]]; then
          msg_error "Invalid WAN NETMASK format. Needs to be 1-32, was $WAN_NETMASK"
          exit
        fi
        echo -e "${DGN}Using WAN NETMASK: ${BGN}$WAN_NETMASK${CL}"
      else
        exit-script
      fi
    fi
  else
    exit-script
  fi
  if MAC1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a WAN MAC Address" 8 58 $GEN_MAC --title "WAN MAC ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $MAC1 ]; then
      MAC="$GEN_MAC"
    else
      MAC="$MAC1"
    fi
    echo -e "${DGN}Using LAN MAC Address: ${BGN}$MAC${CL}"
  else
    exit-script
  fi

  if MAC2=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a LAN MAC Address" 8 58 $GEN_MAC_LAN --title "LAN MAC ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $MAC2 ]; then
      WAN_MAC="$GEN_MAC_LAN"
    else
      WAN_MAC="$MAC2"
    fi
    echo -e "${DGN}Using WAN MAC Address: ${BGN}$WAN_MAC${CL}"
  else
    exit-script
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "ADVANCED SETTINGS COMPLETE" --yesno "Ready to create OPNsense VM?" --no-button Do-Over 10 58); then
    echo -e "${RD}Creating a OPNsense VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

function start_script() {
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "SETTINGS" --yesno "Use Default Settings?" --no-button Advanced 10 58); then
    header_info
    echo -e "${BL}Using Default Settings${CL}"
    default_settings
  else
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

arch_check
pve_check
ssh_check
start_script
post_to_api_vm

msg_info "Validating Storage"
while read -r line; do
  TAG=$(echo $line | awk '{print $1}')
  TYPE=$(echo $line | awk '{printf "%-10s", $2}')
  FREE=$(echo $line | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
  ITEM="  Type: $TYPE Free: $FREE "
  OFFSET=2
  if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
    MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
  fi
  STORAGE_MENU+=("$TAG" "$ITEM" "OFF")
done < <(pvesm status -content images | awk 'NR>1')
VALID=$(pvesm status -content images | awk 'NR>1')
if [ -z "$VALID" ]; then
  msg_error "Unable to detect a valid storage location."
  exit
elif [ $((${#STORAGE_MENU[@]} / 3)) -eq 1 ]; then
  STORAGE=${STORAGE_MENU[0]}
else
  while [ -z "${STORAGE:+x}" ]; do
    STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
      "Which storage pool you would like to use for ${HN}?\nTo make a selection, use the Spacebar.\n" \
      16 $(($MSG_MAX_LENGTH + 23)) 6 \
      "${STORAGE_MENU[@]}" 3>&1 1>&2 2>&3) || exit
  done
fi
msg_ok "Using ${CL}${BL}$STORAGE${CL} ${GN}for Storage Location."
msg_ok "Virtual Machine ID is ${CL}${BL}$VMID${CL}."
msg_info "Retrieving the URL for the OPNsense Qcow2 Disk Image"
URL=https://download.freebsd.org/releases/VM-IMAGES/14.2-RELEASE/amd64/Latest/FreeBSD-14.2-RELEASE-amd64.qcow2.xz
sleep 2
msg_ok "${CL}${BL}${URL}${CL}"
wget -q --show-progress $URL
echo -en "\e[1A\e[0K"
FILE=Fressbsd.qcow2
unxz -cv $(basename $URL) > ${FILE}
msg_ok "Downloaded ${CL}${BL}${FILE}${CL}"

STORAGE_TYPE=$(pvesm status -storage $STORAGE | awk 'NR>1 {print $2}')
case $STORAGE_TYPE in
nfs | dir)
  DISK_EXT=".qcow2"
  DISK_REF="$VMID/"
  DISK_IMPORT="-format qcow2"
  THIN=""
  ;;
btrfs)
  DISK_EXT=".raw"
  DISK_REF="$VMID/"
  DISK_IMPORT="-format raw"
  FORMAT=",efitype=4m"
  THIN=""
  ;;
esac
for i in {0,1}; do
  disk="DISK$i"
  eval DISK${i}=vm-${VMID}-disk-${i}${DISK_EXT:-}
  eval DISK${i}_REF=${STORAGE}:${DISK_REF:-}${!disk}
done

msg_info "Creating a OPNsense VM"
qm create $VMID -agent 1${MACHINE} -tablet 0 -localtime 1 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags proxmox-helper-scripts -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
pvesm alloc $STORAGE $VMID $DISK0 4M 1>&/dev/null
qm importdisk $VMID ${FILE} $STORAGE ${DISK_IMPORT:-} 1>&/dev/null
qm set $VMID \
  -efidisk0 ${DISK0_REF}${FORMAT} \
  -scsi0 ${DISK1_REF},${DISK_CACHE}${THIN}size=2G \
  -boot order=scsi0 \
  -serial0 socket >/dev/null \
  -tags community-scripts
qm resize $VMID scsi0 10G >/dev/null
  DESCRIPTION=$(cat <<EOF
<div align='center'>
  <a href='https://Helper-Scripts.com' target='_blank' rel='noopener noreferrer'>
    <img src='https://raw.githubusercontent.com/michelroegl-brunner/ProxmoxVE/refs/heads/develop/misc/images/logo-81x112.png' alt='Logo' style='width:81px;height:112px;'/>
  </a>

  <h2 style='font-size: 24px; margin: 20px 0;'>OPNsense VM</h2>

  <p style='margin: 16px 0;'>
    <a href='https://ko-fi.com/community_scripts' target='_blank' rel='noopener noreferrer'>
      <img src='https://img.shields.io/badge/&#x2615;-Buy us a coffee-blue' alt='spend Coffee' />
    </a>
  </p>
  
  <span style='margin: 0 10px;'>
    <i class="fa fa-github fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>GitHub</a>
  </span>
  <span style='margin: 0 10px;'>
    <i class="fa fa-comments fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE/discussions' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Discussions</a>
  </span>
  <span style='margin: 0 10px;'>
    <i class="fa fa-exclamation-circle fa-fw" style="color: #f5f5f5;"></i>
    <a href='https://github.com/community-scripts/ProxmoxVE/issues' target='_blank' rel='noopener noreferrer' style='text-decoration: none; color: #00617f;'>Issues</a>
  </span>
</div>
EOF
)
  qm set "$VMID" -description "$DESCRIPTION" >/dev/null  

msg_info "Bridge interfaces are being added."
qm set $VMID \
  -net0 virtio,bridge=${BRG},macaddr=${MAC}${VLAN}${MTU} 2>/dev/null
msg_ok "Bridge interfaces have been successfully added."
  
msg_ok "Created a OPNsense VM ${CL}${BL}(${HN})"
  msg_ok "Starting OPNsense VM (Patience this takes 20-30 minutes)"
  qm start $VMID
  sleep 90
  send_line_to_vm "root"
  send_line_to_vm "fetch https://raw.githubusercontent.com/opnsense/update/master/src/bootstrap/opnsense-bootstrap.sh.in"
  qm set $VMID \
    -net1 virtio,bridge=${WAN_BRG},macaddr=${WAN_MAC} &>/dev/null
  sleep 10
  send_line_to_vm "sh ./opnsense-bootstrap.sh.in -y -f -r 25.1"
  msg_ok "OPNsense VM is being installed, do not close the terminal, or the installation will fail."
  #We need to wait for the OPNsense build proccess to finish, this takes a few minutes
  sleep 1000
  send_line_to_vm "root"
  send_line_to_vm "opnsense"
  send_line_to_vm "2"

  if [ "$IP_ADDR" != "" ]; then
    send_line_to_vm "1"
    send_line_to_vm "n"
    send_line_to_vm "${IP_ADDR}"
    send_line_to_vm "${NETMASK}"
    send_line_to_vm "${LAN_GW}"
    send_line_to_vm "n"
    send_line_to_vm " "
    send_line_to_vm "n"
    send_line_to_vm "n"
    send_line_to_vm " "
    send_line_to_vm "n"
    send_line_to_vm "n"
    send_line_to_vm "n"
    send_line_to_vm "n"
    send_line_to_vm "n"    
  else
    send_line_to_vm "1"
    send_line_to_vm "y"
    send_line_to_vm "n"
    send_line_to_vm "n"  
    send_line_to_vm " "
    send_line_to_vm "n"
    send_line_to_vm "n"   
    send_line_to_vm "n"
  fi
  #we need to wait for the Config changes to be saved
  sleep 20
  if [ "$WAN_IP_ADDR" != "" ]; then
    send_line_to_vm "2"
    send_line_to_vm "2"
    send_line_to_vm "n"
    send_line_to_vm "${WAN_IP_ADDR}"
    send_line_to_vm "${NETMASK}"
    send_line_to_vm "${LAN_GW}"
    send_line_to_vm "n"
    send_line_to_vm " "
    send_line_to_vm "n"
    send_line_to_vm " "
    send_line_to_vm "n"
    send_line_to_vm "n"
    send_line_to_vm "n" 
  fi
  sleep 10
  send_line_to_vm "0"
  msg_ok "Started OPNsense VM"

msg_ok "Completed Successfully!\n"
if [ "$IP_ADDR" != "" ]; then
  echo -e "${INFO}${YW} Access it using the following URL:${CL}"
  echo -e "${TAB}${GATEWAY}${BGN}http://${IP_ADDR}${CL}"
else
  echo -e "${INFO}${YW} LAN IP was DHCP.${CL}"
  echo -e "${INFO}${BGN}To find the IP login to the VM shell${CL}"
fi
