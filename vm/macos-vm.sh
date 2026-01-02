#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: scott (duggasco)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thenickdude/KVM-Opencore

source /dev/stdin <<<$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func)

function header_info {
  clear
  cat <<"EOF"
                            ____  _____
   _ __ ___   __ _  ___  / ___/ / ___/
  | '_ ` _ \ / _` |/ __|| |  | \___ \
  | | | | | | (_| | (__ | |__| |___) |
  |_| |_| |_|\__,_|\___| \____/|____/
     Proxmox VM (Sonoma/Sequoia Fixed)
EOF
}
header_info
echo -e "\n Loading..."

# Configuration
OPENCORE_URL="https://github.com/thenickdude/KVM-Opencore/releases/download/v21/OpenCore-v21.iso.gz"
MACRECOVERY_REPO="https://github.com/acidanthera/OpenCorePkg.git"

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
NSAPP="macos-vm"
var_os="macos"
var_version="sonoma"

# OS Board IDs for macrecovery
declare -A OS_BOARD_IDS=(
  ["ventura"]="Mac-4B682C642B45593E"
  ["sonoma"]="Mac-827FAC58A8FDFA22"
  ["sequoia"]="Mac-7BA5B2D9E42DDD94"
)

declare -A OS_NAMES=(
  ["ventura"]="macOS 13 Ventura"
  ["sonoma"]="macOS 14 Sonoma"
  ["sequoia"]="macOS 15 Sequoia"
)

declare -A OS_RECOVERY_SIZE=(
  ["ventura"]="900"
  ["sonoma"]="900"
  ["sequoia"]="1024"
)

# Colors
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BOLD=$(echo "\033[1m")
BFR="\\r\\033[K"
HOLD=" "
TAB="  "

# Emoji prefixes
CM="${TAB}✔️${TAB}${CL}"
CROSS="${TAB}✖️${TAB}${CL}"
INFO="${TAB}💡${TAB}${CL}"
OS_ICON="${TAB}🍎${TAB}${CL}"
CONTAINERTYPE="${TAB}📦${TAB}${CL}"
DISKSIZE="${TAB}💾${TAB}${CL}"
CPUCORE="${TAB}🧠${TAB}${CL}"
RAMSIZE="${TAB}🛠️${TAB}${CL}"
CONTAINERID="${TAB}🆔${TAB}${CL}"
HOSTNAME="${TAB}🏠${TAB}${CL}"
BRIDGE="${TAB}🌉${TAB}${CL}"
GATEWAY="${TAB}🌐${TAB}${CL}"
DEFAULT="${TAB}⚙️${TAB}${CL}"
MACADDRESS="${TAB}🔗${TAB}${CL}"
VLANTAG="${TAB}🏷️${TAB}${CL}"
CREATING="${TAB}🚀${TAB}${CL}"
ADVANCED="${TAB}🧩${TAB}${CL}"
DOWNLOAD="${TAB}⬇️${TAB}${CL}"

set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "INTERRUPTED"' SIGINT
trap 'post_update_to_api "failed" "TERMINATED"' SIGTERM

function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  post_update_to_api "failed" "${command}"
  echo -e "\n$error_message\n"
  cleanup_vmid
}

function cleanup_vmid() {
  if [ -n "${VMID:-}" ] && qm status $VMID &>/dev/null; then
    qm stop $VMID &>/dev/null || true
    qm destroy $VMID &>/dev/null || true
  fi
}

function cleanup() {
  popd >/dev/null 2>&1 || true
  post_update_to_api "done" "none"
  rm -rf "${TEMP_DIR:-}" 2>/dev/null || true
  umount /tmp/oc-mount 2>/dev/null || true
  umount /tmp/recovery-mount 2>/dev/null || true
}

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

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
  if ! command -v pveversion &>/dev/null; then
    msg_error "This script must be run on a Proxmox VE host."
    exit 1
  fi

  local PVE_VER
  PVE_VER="$(pveversion | awk -F'/' '{print $2}' | awk -F'-' '{print $1}')"

  if [[ "$PVE_VER" =~ ^8\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 9)); then
      msg_error "This version of Proxmox VE is not supported."
      msg_error "Supported: Proxmox VE version 8.0 – 8.9"
      exit 1
    fi
    return 0
  fi

  if [[ "$PVE_VER" =~ ^9\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 1)); then
      msg_error "This version of Proxmox VE is not supported."
      msg_error "Supported: Proxmox VE version 9.0 – 9.1"
      exit 1
    fi
    return 0
  fi

  msg_error "This version of Proxmox VE is not supported."
  msg_error "Supported versions: Proxmox VE 8.0 – 8.x or 9.0 – 9.1"
  exit 1
}

function arch_check() {
  if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    echo -e "\n ${INFO}${YW}macOS VMs require x86_64/amd64 architecture.${CL}\n"
    echo -e "Exiting..."
    sleep 2
    exit
  fi
}

function kvm_check() {
  if [[ $(cat /sys/module/kvm/parameters/ignore_msrs 2>/dev/null) != "Y" ]]; then
    echo -e "\n${INFO}${YW}Warning: KVM ignore_msrs is not enabled.${CL}"
    echo -e "${TAB}macOS may crash without this setting.\n"
    echo -e "${TAB}To fix temporarily:  ${BL}echo 1 > /sys/module/kvm/parameters/ignore_msrs${CL}"
    echo -e "${TAB}To fix permanently:  ${BL}echo 'options kvm ignore_msrs=1' >> /etc/modprobe.d/kvm.conf${CL}"
    echo -e "${TAB}                     ${BL}update-initramfs -k all -u${CL}\n"

    if ! whiptail --backtitle "Proxmox VE Helper Scripts" --title "KVM Warning" --yesno "ignore_msrs is not enabled. Continue anyway?" 10 58; then
      exit 1
    fi
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

function get_valid_nextid() {
  local try_id
  try_id=$(pvesh get /cluster/nextid)
  while true; do
    if [ -f "/etc/pve/qemu-server/${try_id}.conf" ] || [ -f "/etc/pve/lxc/${try_id}.conf" ]; then
      try_id=$((try_id + 1))
      continue
    fi
    if lvs --noheadings -o lv_name 2>/dev/null | grep -qE "(^|[-_])${try_id}($|[-_])"; then
      try_id=$((try_id + 1))
      continue
    fi
    break
  done
  echo "$try_id"
}

function install_dependencies() {
  msg_info "Installing dependencies"
  apt-get update -qq &>/dev/null
  apt-get install -y -qq p7zip-full wget python3 git pv &>/dev/null
  msg_ok "Installed dependencies"
}

function default_settings() {
  MACOS_VERSION="sonoma"
  var_version="$MACOS_VERSION"
  VMID=$(get_valid_nextid)
  CORE_COUNT="4"
  RAM_SIZE="8192"
  DISK_SIZE="80"
  HN="macos-${MACOS_VERSION}"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  START_VM="yes"
  METHOD="default"

  echo -e "${OS_ICON}${BOLD}${DGN}macOS Version: ${BGN}${OS_NAMES[$MACOS_VERSION]}${CL}"
  echo -e "${CONTAINERID}${BOLD}${DGN}Virtual Machine ID: ${BGN}${VMID}${CL}"
  echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}$((RAM_SIZE / 1024))GB${CL}"
  echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}${DISK_SIZE}GB${CL}"
  echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}${HN}${CL}"
  echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}${BRG}${CL}"
  echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}${MAC}${CL}"
  echo -e "${CREATING}${BOLD}${DGN}Creating macOS VM using default settings${CL}"
}

function advanced_settings() {
  METHOD="advanced"

  # macOS Version
  if MACOS_VERSION=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "macOS Version" --radiolist "Choose Version" --cancel-button Exit-Script 12 58 3 \
    "ventura" "macOS 13 Ventura (stable)" OFF \
    "sonoma" "macOS 14 Sonoma" ON \
    "sequoia" "macOS 15 Sequoia (latest)" OFF \
    3>&1 1>&2 2>&3); then
    var_version="$MACOS_VERSION"
    echo -e "${OS_ICON}${BOLD}${DGN}macOS Version: ${BGN}${OS_NAMES[$MACOS_VERSION]}${CL}"
  else
    exit-script
  fi

  # VM ID
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

  # CPU Cores
  if CORE_COUNT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores" 8 58 4 --title "CPU CORES" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$CORE_COUNT" ]; then CORE_COUNT="4"; fi
    echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}$CORE_COUNT${CL}"
  else
    exit-script
  fi

  # RAM
  if RAM_GB=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in GB" 8 58 8 --title "RAM" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$RAM_GB" ]; then RAM_GB="8"; fi
    RAM_SIZE=$((RAM_GB * 1024))
    echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}${RAM_GB}GB${CL}"
  else
    exit-script
  fi

  # Disk Size
  if DISK_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Disk Size in GB" 8 58 80 --title "DISK SIZE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$DISK_SIZE" ]; then DISK_SIZE="80"; fi
    echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}${DISK_SIZE}GB${CL}"
  else
    exit-script
  fi

  # Hostname
  if VM_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Hostname" 8 58 "macos-${MACOS_VERSION}" --title "HOSTNAME" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$VM_NAME" ]; then
      HN="macos-${MACOS_VERSION}"
    else
      HN=$(echo ${VM_NAME,,} | tr -d ' ')
    fi
    echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}$HN${CL}"
  else
    exit-script
  fi

  # Bridge
  if BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Bridge" 8 58 vmbr0 --title "BRIDGE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$BRG" ]; then BRG="vmbr0"; fi
    echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}$BRG${CL}"
  else
    exit-script
  fi

  # MAC Address
  if MAC1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a MAC Address" 8 58 $GEN_MAC --title "MAC ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$MAC1" ]; then
      MAC="$GEN_MAC"
    else
      MAC="$MAC1"
    fi
    echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}$MAC${CL}"
  else
    exit-script
  fi

  # Start VM
  if whiptail --backtitle "Proxmox VE Helper Scripts" --title "START VIRTUAL MACHINE" --yesno "Start VM when completed?" 10 58; then
    echo -e "${GATEWAY}${DGN}Start VM when completed: ${BGN}yes${CL}"
    START_VM="yes"
  else
    echo -e "${GATEWAY}${DGN}Start VM when completed: ${BGN}no${CL}"
    START_VM="no"
  fi

  # Confirm
  if whiptail --backtitle "Proxmox VE Helper Scripts" --title "ADVANCED SETTINGS COMPLETE" --yesno "Ready to create ${OS_NAMES[$MACOS_VERSION]} VM?" --no-button Do-Over 10 58; then
    echo -e "${CREATING}${RD}Creating macOS VM using advanced settings${CL}"
  else
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

function start_script() {
  if whiptail --backtitle "Proxmox VE Helper Scripts" --title "macOS VM" --yesno "This will create a new macOS VM with Sonoma/Sequoia fixes.\n\nRequirements:\n- Intel CPU with AVX2 (Haswell+)\n- KVM ignore_msrs enabled\n\nProceed?" 14 58; then
    :
  else
    header_info && echo -e "${CROSS}${RD}User exited script${CL}\n" && exit
  fi

  if whiptail --backtitle "Proxmox VE Helper Scripts" --title "SETTINGS" --yesno "Use Default Settings?" --no-button Advanced 10 58; then
    header_info
    echo -e "${BL}Using Default Settings${CL}"
    default_settings
  else
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

function select_storage() {
  msg_info "Validating Storage"

  local STORAGE_MENU=()
  while read -r line; do
    TAG=$(echo $line | awk '{print $1}')
    TYPE=$(echo $line | awk '{printf "%-10s", $2}')
    FREE=$(echo $line | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f 2>/dev/null | awk '{printf( "%9sB", $6)}' 2>/dev/null || echo "N/A")
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
    exit 1
  elif [ $((${#STORAGE_MENU[@]} / 3)) -eq 1 ]; then
    STORAGE=${STORAGE_MENU[0]}
  else
    while [ -z "${STORAGE:+x}" ]; do
      STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
        "Which storage pool for the VM disk?\nUse Spacebar to select.\n" \
        16 $(($MSG_MAX_LENGTH + 23)) 6 \
        "${STORAGE_MENU[@]}" 3>&1 1>&2 2>&3) || exit-script
    done
  fi
  msg_ok "Using ${CL}${BL}$STORAGE${CL} ${GN}for Storage Location."

  # ISO Storage
  msg_info "Validating ISO Storage"
  local ISO_MENU=()
  MSG_MAX_LENGTH=0
  while read -r line; do
    TAG=$(echo $line | awk '{print $1}')
    TYPE=$(echo $line | awk '{printf "%-10s", $2}')
    ITEM="  Type: $TYPE"
    OFFSET=2
    if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
      MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
    fi
    ISO_MENU+=("$TAG" "$ITEM" "OFF")
  done < <(pvesm status -content iso | awk 'NR>1')

  if [ $((${#ISO_MENU[@]} / 3)) -eq 1 ]; then
    ISO_STORAGE=${ISO_MENU[0]}
  else
    while [ -z "${ISO_STORAGE:+x}" ]; do
      ISO_STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "ISO Storage" --radiolist \
        "Which storage for OpenCore/Recovery images?\n" \
        16 $(($MSG_MAX_LENGTH + 23)) 6 \
        "${ISO_MENU[@]}" 3>&1 1>&2 2>&3) || exit-script
    done
  fi
  msg_ok "Using ${CL}${BL}$ISO_STORAGE${CL} ${GN}for ISO Storage."
}

function get_iso_path() {
  local storage_type
  storage_type=$(pvesm status 2>/dev/null | awk -v s="$ISO_STORAGE" '$1 == s {print $2}')

  case "$storage_type" in
    nfs|cifs|dir)
      if [[ -d "/mnt/pve/$ISO_STORAGE/template/iso" ]]; then
        echo "/mnt/pve/$ISO_STORAGE/template/iso"
      else
        mkdir -p "/mnt/pve/$ISO_STORAGE/template/iso"
        echo "/mnt/pve/$ISO_STORAGE/template/iso"
      fi
      ;;
    *)
      echo "/var/lib/vz/template/iso"
      ;;
  esac
}

function prepare_opencore() {
  msg_info "Downloading OpenCore v21"
  wget -q --show-progress "$OPENCORE_URL" -O opencore.iso.gz
  gunzip opencore.iso.gz
  msg_ok "Downloaded OpenCore"

  msg_info "Applying Sonoma/Sequoia fixes"
  mkdir -p oc-extract
  7z x opencore.iso -ooc-extract >/dev/null

  # Apply fixes: DmgLoading and ScanPolicy
  local CONFIG_PATH="oc-extract/EFI/OC/config.plist"
  sed -i 's|<string>Signed</string>|<string>Any</string>|' "$CONFIG_PATH"
  sed -i 's|<integer>18809603</integer>|<integer>0</integer>|' "$CONFIG_PATH"

  # Create FAT32 image
  local ISO_PATH=$(get_iso_path)
  OC_IMG="$ISO_PATH/OpenCore-v21-fixed.img"

  dd if=/dev/zero of="$OC_IMG" bs=1M count=150 status=none
  mkfs.vfat -F 32 "$OC_IMG" >/dev/null

  mkdir -p /tmp/oc-mount
  mount -o loop "$OC_IMG" /tmp/oc-mount
  cp -r oc-extract/EFI /tmp/oc-mount/
  umount /tmp/oc-mount

  msg_ok "OpenCore prepared with fixes"
}

function download_recovery() {
  msg_info "Downloading ${OS_NAMES[$MACOS_VERSION]} recovery"

  git clone --depth 1 --filter=blob:none --sparse "$MACRECOVERY_REPO" macrecovery-repo >/dev/null 2>&1
  cd macrecovery-repo
  git sparse-checkout set Utilities/macrecovery >/dev/null 2>&1
  cd Utilities/macrecovery

  local BOARD_ID="${OS_BOARD_IDS[$MACOS_VERSION]}"

  if [[ "$MACOS_VERSION" == "sequoia" ]]; then
    python3 macrecovery.py -b "$BOARD_ID" -m 00000000000000000 -os latest download
  else
    python3 macrecovery.py -b "$BOARD_ID" -m 00000000000000000 download
  fi

  if [[ ! -f com.apple.recovery.boot/BaseSystem.dmg ]]; then
    msg_error "Failed to download recovery image"
    exit 1
  fi

  local ISO_PATH=$(get_iso_path)
  local RECOVERY_SIZE="${OS_RECOVERY_SIZE[$MACOS_VERSION]}"
  RECOVERY_IMG="$ISO_PATH/recovery-${MACOS_VERSION}.img"

  dd if=/dev/zero of="$RECOVERY_IMG" bs=1M count=$RECOVERY_SIZE status=none
  mkfs.vfat -F 32 "$RECOVERY_IMG" >/dev/null

  mkdir -p /tmp/recovery-mount
  mount -o loop "$RECOVERY_IMG" /tmp/recovery-mount
  mkdir -p /tmp/recovery-mount/com.apple.recovery.boot
  cp com.apple.recovery.boot/* /tmp/recovery-mount/com.apple.recovery.boot/
  umount /tmp/recovery-mount

  cd "$TEMP_DIR"
  msg_ok "Downloaded ${OS_NAMES[$MACOS_VERSION]} recovery"
}

function create_vm() {
  msg_info "Creating macOS VM"

  local ISO_PATH=$(get_iso_path)
  local OC_FILE="OpenCore-v21-fixed.img"
  local RECOVERY_FILE="recovery-${MACOS_VERSION}.img"
  local RECOVERY_SIZE="${OS_RECOVERY_SIZE[$MACOS_VERSION]}"

  # Create base VM
  qm create "$VMID" \
    --name "$HN" \
    --ostype other \
    --machine q35 \
    --bios ovmf \
    --cpu host \
    --cores "$CORE_COUNT" \
    --memory "$RAM_SIZE" \
    --balloon 0 \
    --vga vmware \
    --net0 "vmxnet3,bridge=$BRG,macaddr=$MAC" \
    --tags community-script >/dev/null

  # Add EFI disk
  qm set "$VMID" --efidisk0 "${STORAGE}:1,format=raw,efitype=4m,pre-enrolled-keys=0" >/dev/null

  # Add main disk
  qm set "$VMID" --virtio0 "${STORAGE}:${DISK_SIZE},cache=none,discard=on" >/dev/null

  # Add macOS args (AppSMC for macOS boot)
  qm set "$VMID" --args '-device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device qemu-xhci -device usb-kbd -device usb-tablet -global nec-usb-xhci.msi=off -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu host,kvm=on,vendor=GenuineIntel,+kvm_pv_unhalt,+kvm_pv_eoi,+hypervisor,+invtsc' >/dev/null

  # Add boot images via config file (for media=disk)
  local CONFIG_FILE="/etc/pve/qemu-server/${VMID}.conf"
  echo "ide0: ${ISO_STORAGE}:iso/${OC_FILE},cache=unsafe,media=disk,size=150M" >> "$CONFIG_FILE"
  echo "ide2: ${ISO_STORAGE}:iso/${RECOVERY_FILE},cache=unsafe,media=disk,size=${RECOVERY_SIZE}M" >> "$CONFIG_FILE"

  # Set boot order
  qm set "$VMID" --boot order="ide0;virtio0" >/dev/null

  # Add description
  local DESCRIPTION=$(
    cat <<EOF
<div align='center'>
  <a href='https://Helper-Scripts.com' target='_blank' rel='noopener noreferrer'>
    <img src='https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png' alt='Logo' style='width:81px;height:112px;'/>
  </a>

  <h2 style='font-size: 24px; margin: 20px 0;'>macOS ${OS_NAMES[$MACOS_VERSION]} VM</h2>

  <p style='margin: 16px 0;'>
    <a href='https://ko-fi.com/community_scripts' target='_blank' rel='noopener noreferrer'>
      <img src='https://img.shields.io/badge/&#x2615;-Buy us a coffee-blue' alt='Buy Coffee' />
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
  qm set "$VMID" --description "$DESCRIPTION" >/dev/null

  msg_ok "Created macOS VM ${CL}${BL}(${HN})${CL}"
}

function show_completion() {
  local PROXMOX_IP=$(hostname -I | awk '{print $1}')
  local NODE=$(hostname)

  echo -e "\n"
  msg_ok "Completed Successfully!\n"
  echo -e "${CREATING}${GN}macOS ${OS_NAMES[$MACOS_VERSION]} VM has been created!${CL}"
  echo -e "${INFO}${YW} Access the console using the following URL:${CL}"
  echo -e "${TAB}${GATEWAY}${BGN}https://${PROXMOX_IP}:8006/?console=kvm&vmid=${VMID}&node=${NODE}${CL}\n"
  echo -e "${INFO}${YW} Next Steps:${CL}"
  echo -e "${TAB}1. Open the console URL above"
  echo -e "${TAB}2. Select '${MACOS_VERSION^^} (dmg)' in OpenCore boot picker"
  echo -e "${TAB}3. Format the VirtIO disk as APFS in Disk Utility"
  echo -e "${TAB}4. Install macOS"
  echo -e "${TAB}5. After install, copy EFI to main disk for standalone boot\n"
}

# Main execution
check_root
arch_check
pve_check
ssh_check
kvm_check
start_script
post_to_api_vm
install_dependencies
select_storage

msg_ok "Virtual Machine ID is ${CL}${BL}$VMID${CL}."

prepare_opencore
download_recovery
create_vm

if [ "$START_VM" == "yes" ]; then
  msg_info "Starting macOS VM"
  qm start $VMID
  msg_ok "Started macOS VM"
fi

show_completion
