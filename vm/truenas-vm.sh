#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: juronja
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.truenas.com/truenas-community-edition/

source /dev/stdin <<<$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func)

function header_info() {
  clear
  cat <<"EOF"
  ______                _   _____   _____
 /_  __/______  _____  / | / /   | / ___/
  / / / ___/ / / / _ \/  |/ / /| | \__ \
 / / / /  / /_/ /  __/ /|  / ___ |___/ /
/_/ /_/   \__,_/\___/_/ |_/_/  |_/____/
                                           (Community Edition)
EOF
}
header_info
echo -e "\n Loading..."
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")

CL=$(echo "\033[m")
BOLD=$(echo "\033[1m")
BFR="\\r\\033[K"
HOLD=" "
TAB="  "

CM="${TAB}✔️${TAB}${CL}"
CROSS="${TAB}✖️${TAB}${CL}"
INFO="${TAB}💡${TAB}${CL}"
OS="${TAB}🖥️${TAB}${CL}"
CONTAINERTYPE="${TAB}📦${TAB}${CL}"
ISO="${TAB}📀${TAB}${CL}"
DISKSIZE="${TAB}💾${TAB}${CL}"
CPUCORE="${TAB}🧠${TAB}${CL}"
RAMSIZE="${TAB}🛠️${TAB}${CL}"
CONTAINERID="${TAB}🆔${TAB}${CL}"
HOSTNAME="${TAB}🏠${TAB}${CL}"
BRIDGE="${TAB}🌉${TAB}${CL}"
GATEWAY="${TAB}🌐${TAB}${CL}"
DISK="${TAB}💽${TAB}${CL}"
DEFAULT="${TAB}⚙️${TAB}${CL}"
MACADDRESS="${TAB}🔗${TAB}${CL}"
VLANTAG="${TAB}🏷️${TAB}${CL}"
CREATING="${TAB}🚀${TAB}${CL}"
ADVANCED="${TAB}🧩${TAB}${CL}"
CLOUD="${TAB}☁️${TAB}${CL}"

set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP
function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  post_update_to_api "failed" "${command}"
  echo -e "\n$error_message\n"
  cleanup_vmid
}

function truenas_iso_lookup() {
  local BASE_URL="https://download.truenas.com"
  local current_year=$(date +%y)
  local last_year=$(date -d "1 year ago" +%y)
  local year_pattern="${current_year}\.|${last_year}\."

  declare -A latest_stables
  local pre_releases=()

  local all_paths=$(
    curl -sL "$BASE_URL" |
      grep -oE 'href="[^"]+\.iso"' |
      sed 's/href="//; s/"$//' |
      grep -vE '(MASTER|ALPHA)' |
      grep -E "$year_pattern"
  )

  while read -r path; do
    local filename=$(basename "$path")
    local version=$(echo "$filename" | sed -E 's/.*TrueNAS-SCALE-([0-9]{2}\.[0-9]{2}(\.[0-9]+)*(-RC[0-9]|-BETA[0-9])?)\.iso.*/\1/')
    if [[ "$version" =~ (RC|BETA) ]]; then
      pre_releases+=("$path")
    else
      local major_version=$(echo "$version" | cut -d'.' -f1,2)
      local current_stored_path=${latest_stables["$major_version"]}
      if [[ -z "$current_stored_path" ]]; then
        latest_stables["$major_version"]="$path"
      else
        local stored_version=$(basename "$current_stored_path" | sed -E 's/.*TrueNAS-SCALE-([0-9]{2}\.[0-9]{2}(\.[0-9]+)*)\.iso.*/\1/')
        if printf '%s\n' "$version" "$stored_version" | sort -V | tail -n 1 | grep -q "$version"; then
          latest_stables["$major_version"]="$path"
        fi
      fi
    fi
  done <<<"$all_paths"

  for key in "${!latest_stables[@]}"; do
    echo "${latest_stables[$key]#/}"
  done

  for pre in "${pre_releases[@]}"; do
    echo "${pre#/}"
  done | sort -V
}

function get_valid_nextid() {
  local try_id
  try_id=$(pvesh get /cluster/nextid)
  while true; do
    if [ -f "/etc/pve/qemu-server/${try_id}.conf" ] || [ -f "/etc/pve/lxc/${try_id}.conf" ]; then
      try_id=$((try_id + 1))
      continue
    fi
    if lvs --noheadings -o lv_name | grep -qE "(^|[-_])${try_id}($|[-_])"; then
      try_id=$((try_id + 1))
      continue
    fi
    break
  done
  echo "$try_id"
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
if whiptail --backtitle "Proxmox VE Helper Scripts" --title "TrueNAS VM" --yesno "This will create a New TrueNAS VM. Proceed?" 10 58; then
  :
else
  header_info && echo -e "${CROSS}${RD}User exited script${CL}\n" && exit
fi

function msg_info() {
  local msg="$1"
  echo -ne "${TAB}${YW}${HOLD}${msg}${HOLD}"
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR}${CM}${GN}${msg}${CL}"
}

function msg_error() {
  local msg="$1"
  echo -e "${BFR}${CROSS}${RD}${msg}${CL}"
}

function check_root() {
  if [[ "$(id -u)" -ne 0 || $(ps -o comm= -p $PPID) == "sudo" ]]; then
    clear
    msg_error "Please run this script as root."
    echo -e "\nExiting..."
    sleep 2
    exit
  fi
}

function pve_check() {
  local PVE_VER
  PVE_VER="$(pveversion | awk -F'/' '{print $2}' | awk -F'-' '{print $1}')"

  if [[ "$PVE_VER" =~ ^8\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 9)); then
      msg_error "This version of Proxmox VE is not supported."
      msg_error "Supported: Proxmox VE version 8.0 – 8.9"
      exit 105
    fi
    return 0
  fi

  if [[ "$PVE_VER" =~ ^9\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 1)); then
      msg_error "This version of Proxmox VE is not yet supported."
      msg_error "Supported: Proxmox VE version 9.0 – 9.1"
      exit 105
    fi
    return 0
  fi

  msg_error "This version of Proxmox VE is not supported."
  msg_error "Supported versions: Proxmox VE 8.0 – 8.x or 9.0 – 9.1"
  exit 105
}

function arch_check() {
  if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    echo -e "\n ${INFO}${YWB}This script will not work with PiMox! \n"
    echo -e "\n ${YWB}Visit https://github.com/asylumexp/Proxmox for ARM64 support. \n"
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
  echo -e "\n${CROSS}${RD}User exited script${CL}\n"
  exit
}

function default_settings() {
  VMID=$(get_valid_nextid)
  ISO_DEFAULT="latest stable"
  FORMAT=""
  MACHINE="q35"
  DISK_SIZE="16"
  HN="truenas"
  CPU_TYPE="host"
  CORE_COUNT="2"
  RAM_SIZE="8192"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  METHOD="default"
  echo -e "${CONTAINERID}${BOLD}${DGN}Virtual Machine ID: ${BGN}${VMID}${CL}"
  echo -e "${ISO}${BOLD}${DGN}ISO Chosen: ${BGN}${ISO_DEFAULT}${CL}"
  echo -e "${CONTAINERTYPE}${BOLD}${DGN}Machine Type: ${BGN}${MACHINE}${CL}"
  echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}${DISK_SIZE}${CL}"
  echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}${HN}${CL}"
  echo -e "${OS}${BOLD}${DGN}CPU Model: ${BGN}${CPU_TYPE}${CL}"
  echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}${RAM_SIZE}${CL}"
  echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}${BRG}${CL}"
  echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}${MAC}${CL}"
  echo -e "${VLANTAG}${BOLD}${DGN}VLAN: ${BGN}Default${CL}"
  echo -e "${DEFAULT}${BOLD}${DGN}Interface MTU Size: ${BGN}Default${CL}"
  echo -e "${GATEWAY}${BOLD}${DGN}Start VM when completed: ${BGN}yes${CL}"
  echo -e "${CREATING}${BOLD}${DGN}Creating a TrueNAS VM using the above default settings${CL}"
}

function advanced_settings() {
  DISK_SIZE="16"
  HN="truenas"
  CORE_COUNT="2"
  RAM_SIZE="8192"
  BRG="vmbr0"

  METHOD="advanced"
  [ -z "${VMID:-}" ] && VMID=$(get_valid_nextid)
  while true; do
    if VMID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Virtual Machine ID" 8 58 $VMID --title "VIRTUAL MACHINE ID" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
      if [ -z "$VMID" ]; then
        VMID=$(get_valid_nextid)
      fi
      if pct status "$VMID" &>/dev/null || qm status "$VMID" &>/dev/null; then
        echo -e "${CROSS}${RD} ID $VMID is already in use${CL}"
        sleep 2
        continue
      fi
      echo -e "${CONTAINERID}${BOLD}${DGN}Virtual Machine ID: ${BGN}$VMID${CL}"
      break
    else
      exit-script
    fi
  done

  ISOARRAY=()
  mapfile -t ALL_ISOS < <(truenas_iso_lookup | sort -V)
  ISO_COUNT=${#ALL_ISOS[@]}

  if [ $ISO_COUNT -eq 0 ]; then
    echo "No ISOs found."
    exit 115
  fi

  # Identify the index of the last stable release
  LAST_STABLE_INDEX=-1
  for i in "${!ALL_ISOS[@]}"; do
    if [[ ! "${ALL_ISOS[$i]}" =~ (BETA|RC) ]]; then
      LAST_STABLE_INDEX=$i
    fi
  done

  # Build the whiptail array
  for i in "${!ALL_ISOS[@]}"; do
    ISOPATH="${ALL_ISOS[$i]}"
    FILENAME=$(basename "$ISOPATH")

    # Select ON if it's the last stable found, OR fallback to last item if no stable exists
    if [[ "$i" -eq "$LAST_STABLE_INDEX" ]]; then
      ISOARRAY+=("$ISOPATH" "$FILENAME" "ON")
    elif [[ "$LAST_STABLE_INDEX" -eq -1 && "$i" -eq "$((ISO_COUNT - 1))" ]]; then
      # Fallback: if somehow no stable is found, select the very last item
      ISOARRAY+=("$ISOPATH" "$FILENAME" "ON")
    else
      ISOARRAY+=("$ISOPATH" "$FILENAME" "OFF")
    fi
  done

  if SELECTED_ISO=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SELECT ISO TO INSTALL" --notags --radiolist "\nSelect version (BETA/RC/Latest stable):" 20 58 12 "${ISOARRAY[@]}" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    echo -e "${ISO}${BOLD}${DGN}ISO Chosen: ${BGN}$(basename "$SELECTED_ISO")${CL}"
  else
    exit-script
  fi

  if DISK_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Disk Size in GiB (e.g., 10, 20)" 8 58 "$DISK_SIZE" --title "DISK SIZE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    DISK_SIZE=$(echo "$DISK_SIZE" | tr -d ' ')
    if [[ "$DISK_SIZE" =~ ^[0-9]+$ ]]; then
      echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}$DISK_SIZE${CL}"
    else
      echo -e "${DISKSIZE}${BOLD}${RD}Invalid Disk Size. Please use a number (e.g., 10).${CL}"
      exit-script
    fi
  else
    exit-script
  fi

  if VM_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Hostname" 8 58 "$HN" --title "HOSTNAME" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $VM_NAME ]; then
      echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}$HN${CL}"
    else
      HN=$(echo ${VM_NAME,,} | tr -d ' ')
      echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}$HN${CL}"
    fi
  else
    exit-script
  fi

  if CPU_TYPE1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CPU MODEL" --radiolist "Choose CPU Model" --cancel-button Exit-Script 10 58 2 \
    "KVM64" "Default – safe for migration/compatibility" OFF \
    "Host" "Use host CPU features (faster, no migration)" ON \
    3>&1 1>&2 2>&3); then
    case "$CPU_TYPE1" in
    Host)
      echo -e "${OS}${BOLD}${DGN}CPU Model: ${BGN}Host${CL}"
      CPU_TYPE="host"
      ;;
    *)
      echo -e "${OS}${BOLD}${DGN}CPU Model: ${BGN}KVM64${CL}"
      CPU_TYPE=""
      ;;
    esac
  else
    exit-script
  fi

  if CORE_COUNT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores" 8 58 "$CORE_COUNT" --title "CORE COUNT" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $CORE_COUNT ]; then
      CORE_COUNT="2"
      echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}$CORE_COUNT${CL}"
    else
      echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}$CORE_COUNT${CL}"
    fi
  else
    exit-script
  fi

  if RAM_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in MiB" 8 58 "$RAM_SIZE" --title "RAM" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $RAM_SIZE ]; then
      RAM_SIZE="8192"
      echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}$RAM_SIZE${CL}"
    else
      echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}$RAM_SIZE${CL}"
    fi
  else
    exit-script
  fi

  if BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Bridge" 8 58 "$BRG" --title "BRIDGE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $BRG ]; then
      BRG="vmbr0"
      echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}$BRG${CL}"
    else
      echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}$BRG${CL}"
    fi
  else
    exit-script
  fi

  if MAC1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a MAC Address" 8 58 $GEN_MAC --title "MAC ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $MAC1 ]; then
      MAC="$GEN_MAC"
      echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}$MAC${CL}"
    else
      MAC="$MAC1"
      echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}$MAC1${CL}"
    fi
  else
    exit-script
  fi

  if VLAN1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Vlan(leave blank for default)" 8 58 --title "VLAN" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $VLAN1 ]; then
      VLAN1="Default"
      VLAN=""
      echo -e "${VLANTAG}${BOLD}${DGN}VLAN: ${BGN}$VLAN1${CL}"
    else
      VLAN=",tag=$VLAN1"
      echo -e "${VLANTAG}${BOLD}${DGN}VLAN: ${BGN}$VLAN1${CL}"
    fi
  else
    exit-script
  fi

  if MTU1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Interface MTU Size (leave blank for default)" 8 58 --title "MTU SIZE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z $MTU1 ]; then
      MTU1="Default"
      MTU=""
      echo -e "${DEFAULT}${BOLD}${DGN}Interface MTU Size: ${BGN}$MTU1${CL}"
    else
      MTU=",mtu=$MTU1"
      echo -e "${DEFAULT}${BOLD}${DGN}Interface MTU Size: ${BGN}$MTU1${CL}"
    fi
  else
    exit-script
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "IMPORT ONBOARD DISKS" --yesno "Would you like to import onboard disks?" 10 58); then
    echo -e "${DISK}${BOLD}${DGN}Import onboard disks: ${BGN}yes${CL}"
    IMPORT_DISKS="yes"
  else
    echo -e "${DISK}${BOLD}${DGN}Import onboard disks: ${BGN}no${CL}"
    IMPORT_DISKS="no"
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "START VIRTUAL MACHINE" --yesno "Start VM when completed?" 10 58); then
    echo -e "${GATEWAY}${BOLD}${DGN}Start VM when completed: ${BGN}yes${CL}"
    START_VM="yes"
  else
    echo -e "${GATEWAY}${BOLD}${DGN}Start VM when completed: ${BGN}no${CL}"
    START_VM="no"
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "ADVANCED SETTINGS COMPLETE" --yesno "Ready to create a TrueNAS VM?" --no-button Do-Over 10 58); then
    echo -e "${CREATING}${BOLD}${DGN}Creating a TrueNAS VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

function start_script() {
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "SETTINGS" --yesno "Use Default Settings?" --no-button Advanced 10 58); then
    header_info
    echo -e "${DEFAULT}${BOLD}${BL}Using Default Settings${CL}"
    default_settings
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}
check_root
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
    if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID >/dev/null; then kill $SPINNER_PID >/dev/null; fi
    printf "\e[?25h"
    STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
      "Which storage pool would you like to use for ${HN}?\nTo make a selection, use the Spacebar.\n" \
      16 $(($MSG_MAX_LENGTH + 23)) 6 \
      "${STORAGE_MENU[@]}" 3>&1 1>&2 2>&3)
  done
fi
msg_ok "Using ${CL}${BL}$STORAGE${CL} ${GN}for Storage Location."
msg_ok "Virtual Machine ID is ${CL}${BL}$VMID${CL}."

if [ -z "${SELECTED_ISO:-}" ]; then
  SELECTED_ISO=$(truenas_iso_lookup | grep -vE 'RC|BETA' | sort -V | tail -n 1)

  if [ -z "$SELECTED_ISO" ]; then
    msg_error "Could not find a stable ISO for fallback."
    exit 115
  fi
fi

FULL_URL="https://download.truenas.com/${SELECTED_ISO#/}"
ISO_NAME=$(basename "$FULL_URL")
CACHE_DIR="/var/lib/vz/template/iso"
CACHE_FILE="$CACHE_DIR/$ISO_NAME"

if [[ ! -s "$CACHE_FILE" ]]; then
  msg_info "Retrieving the ISO for the TrueNAS Disk Image"
  curl -f#SL -o "$CACHE_FILE" "$FULL_URL"
  msg_ok "Downloaded ${CL}${BL}$(basename "$CACHE_FILE")${CL}"
else
  msg_ok "Using cached image ${CL}${BL}$(basename "$CACHE_FILE")${CL}"
fi

set -o pipefail
msg_info "Creating TrueNAS VM shell"
qm create "$VMID" -machine q35 -bios ovmf -agent enabled=1 -tablet 0 -localtime 1 -cpu "$CPU_TYPE" \
  -cores "$CORE_COUNT" -memory "$RAM_SIZE" -balloon 0 -name "$HN" -tags community-script \
  -net0 "virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU" -onboot 1 -ostype l26 \
  -efidisk0 $STORAGE:1,efitype=4m,pre-enrolled-keys=0 -sata0 $STORAGE:$DISK_SIZE,ssd=1 \
  -scsihw virtio-scsi-single -cdrom local:iso/$ISO_NAME -vga virtio >/dev/null
msg_ok "Created VM shell"

if [ "$IMPORT_DISKS" == "yes" ]; then
  msg_info "Importing onboard disks"
  DISKARRAY=()
  SCSI_NR=0

  while read -r LSOUTPUT; do
    TRUNCATED="${LSOUTPUT:0:45}"
    if [ ${#LSOUTPUT} -gt 45 ]; then
      TRUNCATED="${TRUNCATED}..."
    fi
    DISKARRAY+=("$LSOUTPUT" "$TRUNCATED" "OFF")
  done < <(ls /dev/disk/by-id | grep -E '^ata-|^nvme-|^usb-' | grep -v 'part')

  SELECTIONS=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SELECT DISKS TO IMPORT" --checklist "\nSelect disk IDs to import. (Use Spacebar to select)\n" --notags --cancel-button "Exit Script" 20 58 10 "${DISKARRAY[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

  for SELECTION in $SELECTIONS; do
    ((++SCSI_NR))

    ID_SERIAL=$(udevadm info --query=property --value --property=ID_SERIAL_SHORT "/dev/disk/by-id/$SELECTION")
    ID_SERIAL=${ID_SERIAL:0:20}

    qm set $VMID --scsi$SCSI_NR /dev/disk/by-id/$SELECTION,serial=$ID_SERIAL
  done
  msg_ok "Disks imported successfully"
fi

DESCRIPTION=$(
  cat <<EOF
<div align='center'>
  <a href='https://Helper-Scripts.com' target='_blank' rel='noopener noreferrer'>
    <img src='https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png' alt='Logo' style='width:81px;height:112px;'/>
  </a>

  <h2 style='font-size: 24px; margin: 20px 0;'>TrueNAS Community Edition</h2>

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

sleep 3

msg_ok "Created a TrueNAS VM ${CL}${BL}(${HN})"
if [ "$START_VM" == "yes" ]; then
  msg_info "Starting TrueNAS VM"
  qm start $VMID
  msg_ok "Started TrueNAS VM"
fi

msg_ok "Completed Successfully!\n"
