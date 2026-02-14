#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Wassim Mehanna (lucid-fabrics)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func)"

function header_info {
  clear
  cat <<"EOF"
                        ____  _____   _    ____  ___
   ____ ___  ____ _____/ __ \/ ___/  | |  / /  |/  /
  / __ `__ \/ __ `/ __/ / / /\__ \   | | / / /|_/ /
 / / / / / / /_/ / /_/ /_/ /___/ /   | |/ / /  / /
/_/ /_/ /_/\__,_/\__/\____//____/    |___/_/  /_/

EOF
}
header_info
echo -e "\n Loading..."

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
NSAPP="macos-vm"
var_os="macos"
DISK_SIZE="64G"

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

CM="${TAB}✔️${TAB}${CL}"
CROSS="${TAB}✖️${TAB}${CL}"
INFO="${TAB}💡${TAB}${CL}"
OS="${TAB}🖥️${TAB}${CL}"
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

# ── macOS version definitions ──
declare -A MACOS_LABELS=(
  ["sonoma"]="macOS Sonoma 14"
  ["sequoia"]="macOS Sequoia 15"
  ["tahoe"]="macOS Tahoe 26"
)
declare -A MACOS_BOARD_IDS=(
  ["sonoma"]="Mac-827FAC58A8FDFA22"
  ["sequoia"]="Mac-27AD2F918AE68F61"
  ["tahoe"]="Mac-27AD2F918AE68F61"
)
declare -A MACOS_OS_TYPE=(
  ["sonoma"]="default"
  ["sequoia"]="default"
  ["tahoe"]="latest"
)
declare -A SMBIOS_MODELS=(
  ["sonoma"]="iMacPro1,1"
  ["sequoia"]="iMacPro1,1"
  ["tahoe"]="MacPro7,1"
)

# ── OpenCore ISO download URL ──
OC_URL="https://github.com/lucid-fabrics/osx-proxmox-next/releases/download/assets/opencore-osx-proxmox-vm.iso"

set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" 130' SIGINT
trap 'post_update_to_api "failed" 143' SIGTERM

function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  post_update_to_api "failed" "${exit_code}"
  echo -e "\n$error_message\n"
  cleanup_vmid
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

function cleanup_vmid() {
  if qm status "$VMID" &>/dev/null; then
    qm stop "$VMID" &>/dev/null
    qm destroy "$VMID" &>/dev/null
  fi
}

function cleanup() {
  [ -n "${BUILD_SRC_MNT:-}" ] && umount "$BUILD_SRC_MNT" 2>/dev/null || true
  [ -n "${BUILD_DEST_MNT:-}" ] && umount "$BUILD_DEST_MNT" 2>/dev/null || true
  [ -n "${BUILD_LOOP:-}" ] && losetup -d "$BUILD_LOOP" 2>/dev/null || true
  popd >/dev/null 2>/dev/null || true
  rm -rf "${TEMP_DIR:-}"
}

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

pve_check() {
  local PVE_VER
  PVE_VER="$(pveversion | awk -F'/' '{print $2}' | awk -F'-' '{print $1}')"
  if [[ "$PVE_VER" =~ ^8\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 9)); then
      msg_error "Requires Proxmox VE 8.0–8.9"
      exit 1
    fi
    return 0
  fi
  if [[ "$PVE_VER" =~ ^9\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 1)); then
      msg_error "Requires Proxmox VE 9.0–9.1"
      exit 1
    fi
    return 0
  fi
  msg_error "Requires Proxmox VE 8.x or 9.x"
  exit 1
}

function arch_check() {
  if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    echo -e "\n ${INFO}${YW}macOS VMs require Intel/AMD (amd64) architecture.${CL}\n"
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

# ── Check required build tools ──
function check_dependencies() {
  local missing=()
  for cmd in dmg2img sgdisk partprobe losetup mkfs.fat curl python3; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    msg_info "Installing missing dependencies: ${missing[*]}"
    apt-get update -qq &>/dev/null
    local pkg_map=(
      "dmg2img:dmg2img"
      "sgdisk:gdisk"
      "partprobe:parted"
      "losetup:mount"
      "mkfs.fat:dosfstools"
      "curl:curl"
      "python3:python3"
    )
    for entry in "${pkg_map[@]}"; do
      local cmd="${entry%%:*}"
      local pkg="${entry#*:}"
      if ! command -v "$cmd" &>/dev/null; then
        apt-get install -y "$pkg" &>/dev/null || {
          msg_error "Failed to install $pkg (provides $cmd)"
          echo -e "\nInstall manually: apt install $pkg"
          exit 1
        }
      fi
    done
    msg_ok "Installed dependencies"
  fi
}

# ── Generate SMBIOS identity ──
function generate_smbios() {
  local macos_ver="$1"
  SMBIOS_SERIAL=$(cat /dev/urandom | tr -dc 'A-Z0-9' | head -c 12)
  SMBIOS_UUID=$(cat /proc/sys/kernel/random/uuid | tr '[:lower:]' '[:upper:]')
  SMBIOS_MODEL="${SMBIOS_MODELS[$macos_ver]:-iMacPro1,1}"
}

# ── Download macOS recovery via Apple's osrecovery API ──
# Protocol reverse-engineered from OpenCorePkg macrecovery.py
function download_recovery() {
  local macos_ver="$1"
  local output_img="$2"
  local board_id="${MACOS_BOARD_IDS[$macos_ver]}"
  local os_type="${MACOS_OS_TYPE[$macos_ver]}"

  msg_info "Downloading macOS ${MACOS_LABELS[$macos_ver]} recovery image"

  local cookie_jar
  cookie_jar=$(mktemp)

  # Step 1: GET / to obtain session cookie
  curl -sS "http://osrecovery.apple.com/" \
    -H "Host: osrecovery.apple.com" \
    -H "Connection: close" \
    -H "User-Agent: InternetRecovery/1.0" \
    -c "$cookie_jar" \
    -o /dev/null 2>/dev/null || true

  # Step 2: POST to RecoveryImage with session cookie
  # cid=16 hex, k=64 hex, fg=64 hex (random each request), sn=17 zeros
  local cid k fg
  cid=$(openssl rand -hex 8 | tr '[:lower:]' '[:upper:]')
  k=$(openssl rand -hex 32 | tr '[:lower:]' '[:upper:]')
  fg=$(openssl rand -hex 32 | tr '[:lower:]' '[:upper:]')

  local post_body resp_body http_code
  resp_body=$(mktemp)
  # Body fields are newline-separated (not &-joined)
  post_body="cid=${cid}
sn=00000000000000000
bid=${board_id}
k=${k}
os=${os_type}
fg=${fg}"

  http_code=$(curl -sS -w "%{http_code}" -X POST "http://osrecovery.apple.com/InstallationPayload/RecoveryImage" \
    -H "Host: osrecovery.apple.com" \
    -H "Connection: close" \
    -H "User-Agent: InternetRecovery/1.0" \
    -H "Content-Type: text/plain" \
    -b "$cookie_jar" \
    --data-binary "$post_body" \
    -o "$resp_body" 2>/dev/null)
  rm -f "$cookie_jar"

  if [[ ! "$http_code" =~ ^2 ]]; then
    msg_error "Apple osrecovery API returned HTTP $http_code"
    msg_error "$(cat "$resp_body" 2>/dev/null)"
    rm -f "$resp_body"
    exit 1
  fi

  # Step 3: Parse response body (KEY: VALUE format, not HTTP headers)
  local image_url image_sess
  image_url=$(grep "^AU: " "$resp_body" | sed 's/^AU: //;s/\r//' | head -1)
  image_sess=$(grep "^AT: " "$resp_body" | sed 's/^AT: //;s/\r//' | head -1)
  rm -f "$resp_body"

  if [ -z "$image_url" ]; then
    msg_error "Failed to get recovery image URL from Apple"
    msg_error "This can happen if Apple's recovery servers are temporarily unavailable."
    exit 1
  fi

  # Step 4: Download BaseSystem.dmg (URL from AU: is already complete)
  # Apple's CDN can reset connections on large downloads — retry with resume
  local base_dmg="${output_img%.img}.dmg"
  local max_retries=5
  local attempt=0
  while true; do
    if curl -fSL -C - -o "$base_dmg" \
      --retry 3 --retry-delay 5 \
      -H "User-Agent: InternetRecovery/1.0" \
      ${image_sess:+-H "Cookie: AssetToken=${image_sess}"} \
      "$image_url"; then
      break
    fi
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$max_retries" ]; then
      msg_error "Failed to download BaseSystem.dmg after $max_retries attempts"
      rm -f "$base_dmg"
      exit 1
    fi
    msg_info "Download interrupted, resuming (attempt $((attempt + 1))/$max_retries)..."
    sleep 3
  done

  # Step 5: Convert DMG to raw image using dmg2img
  msg_info "Converting BaseSystem.dmg to raw disk image"
  dmg2img "$base_dmg" "$output_img" &>/dev/null || {
    msg_error "dmg2img conversion failed"
    rm -f "$base_dmg" "$output_img"
    exit 1
  }
  rm -f "$base_dmg"
  msg_ok "Downloaded and converted recovery image"
}

# ── Build OpenCore GPT+ESP disk from source ISO ──
function build_opencore_disk() {
  local source_iso="$1"
  local dest_disk="$2"
  local macos_ver="$3"

  msg_info "Building OpenCore boot disk (GPT+ESP)"

  # Create 1GB blank disk
  dd if=/dev/zero of="$dest_disk" bs=1M count=1024 status=none

  # Partition as GPT with EFI System Partition
  sgdisk -Z "$dest_disk" &>/dev/null
  sgdisk -n 1:0:0 -t 1:EF00 -c 1:OPENCORE "$dest_disk" &>/dev/null

  # Set up loop device for destination (tracked globally for cleanup)
  local dest_loop
  dest_loop=$(losetup -fP --show "$dest_disk")
  BUILD_LOOP="$dest_loop"
  partprobe "$dest_loop" 2>/dev/null || true
  sleep 1

  # Format ESP partition
  mkfs.fat -F 32 "${dest_loop}p1" &>/dev/null

  # Mount destination ESP
  local dest_mnt
  dest_mnt=$(mktemp -d)
  mount "${dest_loop}p1" "$dest_mnt"
  BUILD_DEST_MNT="$dest_mnt"

  # Mount source ISO
  local src_mnt
  src_mnt=$(mktemp -d)
  mount -o loop,ro "$source_iso" "$src_mnt"
  BUILD_SRC_MNT="$src_mnt"

  # Copy OpenCore files
  cp -a "$src_mnt"/* "$dest_mnt"/ 2>/dev/null || cp -a "$src_mnt"/. "$dest_mnt"/ 2>/dev/null || true

  # Validate EFI structure was copied
  if [ ! -d "$dest_mnt/EFI/OC" ]; then
    msg_error "OpenCore ISO does not contain expected EFI/OC directory. ISO may be corrupt."
    umount "$dest_mnt" 2>/dev/null || true
    umount "$src_mnt" 2>/dev/null || true
    losetup -d "$dest_loop" 2>/dev/null || true
    rm -rf "$dest_mnt" "$src_mnt"
    exit 1
  fi

  # Patch config.plist for VM compatibility
  if [ -f "$dest_mnt/EFI/OC/config.plist" ]; then
    python3 -c "
import plistlib, sys
path = sys.argv[1]
with open(path, 'rb') as f:
    pl = plistlib.load(f)
# ScanPolicy=0: scan all devices
pl.setdefault('Misc', {}).setdefault('Security', {})['ScanPolicy'] = 0
# DmgLoading=Any
pl['Misc']['Security']['DmgLoading'] = 'Any'
# Timeout=0: wait for user
pl['Misc'].setdefault('Boot', {})['Timeout'] = 0
# SIP partially disabled for kext loading
nvram = pl.setdefault('NVRAM', {}).setdefault('Add', {}).setdefault('7C436110-AB2A-4BBB-A880-FE41995C9F82', {})
nvram['csr-active-config'] = b'\x26\x0f\x00\x00'
nvram['boot-args'] = 'keepsyms=1 -v'
with open(path, 'wb') as f:
    plistlib.dump(pl, f)
" "$dest_mnt/EFI/OC/config.plist" || {
      msg_error "Failed to patch OpenCore config.plist"
      umount "$dest_mnt" 2>/dev/null || true
      umount "$src_mnt" 2>/dev/null || true
      losetup -d "$dest_loop" 2>/dev/null || true
      rm -rf "$dest_mnt" "$src_mnt"
      exit 1
    }
  fi

  # Cleanup mounts
  umount "$src_mnt" 2>/dev/null || true
  umount "$dest_mnt" 2>/dev/null || true
  losetup -d "$dest_loop" 2>/dev/null || true
  rm -rf "$dest_mnt" "$src_mnt"
  BUILD_SRC_MNT="" BUILD_DEST_MNT="" BUILD_LOOP=""

  msg_ok "Built OpenCore boot disk"
}

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR" >/dev/null

if whiptail --backtitle "Proxmox VE Helper Scripts" --title "macOS VM" --yesno "This will create a new macOS VM on Proxmox.\n\nRequirements:\n  - Intel CPU with VT-x\n  - 64GB+ free disk space\n  - Internet access (downloads ~1GB)\n\nProceed?" 14 58; then
  :
else
  header_info && echo -e "${CROSS}${RD}User exited script${CL}\n" && exit
fi

function default_settings() {
  MACOS_VER="sequoia"
  var_version="15"
  VMID=$(get_valid_nextid)
  DISK_SIZE="64G"
  HN="macos-sequoia"
  CORE_COUNT="4"
  RAM_SIZE="8192"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  METHOD="default"
  echo -e "${OS}${BOLD}${DGN}macOS Version: ${BGN}${MACOS_LABELS[$MACOS_VER]}${CL}"
  echo -e "${CONTAINERID}${BOLD}${DGN}Virtual Machine ID: ${BGN}${VMID}${CL}"
  echo -e "${CONTAINERTYPE}${BOLD}${DGN}Machine Type: ${BGN}q35${CL}"
  echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}${DISK_SIZE}${CL}"
  echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}${HN}${CL}"
  echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}${RAM_SIZE}${CL}"
  echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}${BRG}${CL}"
  echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}${MAC}${CL}"
  echo -e "${VLANTAG}${BOLD}${DGN}VLAN: ${BGN}Default${CL}"
  echo -e "${DEFAULT}${BOLD}${DGN}Interface MTU Size: ${BGN}Default${CL}"
  echo -e "${GATEWAY}${BOLD}${DGN}Start VM when completed: ${BGN}yes${CL}"
  echo -e "${CREATING}${BOLD}${DGN}Creating a macOS VM using the above default settings${CL}"
}

function advanced_settings() {
  METHOD="advanced"

  if MACOS_VER=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "macOS Version" --radiolist "Choose macOS version" --cancel-button Exit-Script 12 58 3 \
    "sonoma" "macOS Sonoma 14 (stable)  " OFF \
    "sequoia" "macOS Sequoia 15 (stable)  " ON \
    "tahoe" "macOS Tahoe 26 (stable)  " OFF \
    3>&1 1>&2 2>&3); then
    echo -e "${OS}${BOLD}${DGN}macOS Version: ${BGN}${MACOS_LABELS[$MACOS_VER]}${CL}"
    case "$MACOS_VER" in
    sonoma) var_version="14" ;;
    sequoia) var_version="15" ;;
    tahoe) var_version="26" ;;
    esac
  else
    exit-script
  fi

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

  if DISK_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Disk Size in GiB (minimum 64)" 8 58 64 --title "DISK SIZE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    DISK_SIZE=$(echo "$DISK_SIZE" | tr -d ' ')
    if [[ "$DISK_SIZE" =~ ^[0-9]+$ ]]; then
      if [ "$DISK_SIZE" -lt 64 ]; then
        msg_error "Disk size must be at least 64 GiB for macOS"
        exit-script
      fi
      DISK_SIZE="${DISK_SIZE}G"
      echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}$DISK_SIZE${CL}"
    elif [[ "$DISK_SIZE" =~ ^[0-9]+G$ ]]; then
      local num="${DISK_SIZE%G}"
      if [ "$num" -lt 64 ]; then
        msg_error "Disk size must be at least 64 GiB for macOS"
        exit-script
      fi
      echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}$DISK_SIZE${CL}"
    else
      msg_error "Invalid Disk Size. Please use a number (e.g., 64 or 64G)."
      exit-script
    fi
  else
    exit-script
  fi

  local default_hn="macos-${MACOS_VER}"
  if VM_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Hostname" 8 58 "$default_hn" --title "HOSTNAME" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$VM_NAME" ]; then
      HN="$default_hn"
    else
      HN=$(echo "${VM_NAME,,}" | tr -d ' ')
    fi
    echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}$HN${CL}"
  else
    exit-script
  fi

  if CORE_COUNT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores (minimum 2)" 8 58 4 --title "CORE COUNT" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$CORE_COUNT" ]; then
      CORE_COUNT="4"
    fi
    if [ "$CORE_COUNT" -lt 2 ] 2>/dev/null; then
      msg_error "At least 2 CPU cores are required for macOS"
      exit-script
    fi
    echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}$CORE_COUNT${CL}"
  else
    exit-script
  fi

  if RAM_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in MiB (minimum 4096)" 8 58 8192 --title "RAM" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$RAM_SIZE" ]; then
      RAM_SIZE="8192"
    fi
    if [ "$RAM_SIZE" -lt 4096 ] 2>/dev/null; then
      msg_error "At least 4096 MiB RAM is required for macOS"
      exit-script
    fi
    echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}$RAM_SIZE${CL}"
  else
    exit-script
  fi

  if BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Bridge" 8 58 vmbr0 --title "BRIDGE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$BRG" ]; then
      BRG="vmbr0"
    fi
    echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}$BRG${CL}"
  else
    exit-script
  fi

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

  if VLAN1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a VLAN (leave blank for default)" 8 58 --title "VLAN" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$VLAN1" ]; then
      VLAN1="Default"
      VLAN=""
    else
      VLAN=",tag=$VLAN1"
    fi
    echo -e "${VLANTAG}${BOLD}${DGN}VLAN: ${BGN}$VLAN1${CL}"
  else
    exit-script
  fi

  if MTU1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Interface MTU Size (leave blank for default)" 8 58 --title "MTU SIZE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$MTU1" ]; then
      MTU1="Default"
      MTU=""
    else
      MTU=",mtu=$MTU1"
    fi
    echo -e "${DEFAULT}${BOLD}${DGN}Interface MTU Size: ${BGN}$MTU1${CL}"
  else
    exit-script
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "START VIRTUAL MACHINE" --yesno "Start VM when completed?" 10 58); then
    echo -e "${DGN}Start VM when completed: ${BGN}yes${CL}"
    START_VM="yes"
  else
    echo -e "${DGN}Start VM when completed: ${BGN}no${CL}"
    START_VM="no"
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "ADVANCED SETTINGS COMPLETE" --yesno "Ready to create ${MACOS_LABELS[$MACOS_VER]} VM?" --no-button Do-Over 10 58); then
    echo -e "${RD}Creating a macOS VM using the above advanced settings${CL}"
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

check_root
arch_check
pve_check
ssh_check
check_dependencies
start_script
post_to_api_vm
start_install_timer

# ── Storage selection ──
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


# ── Download OpenCore ISO ──
CACHE_DIR="/var/lib/vz/template/cache"
mkdir -p "$CACHE_DIR"
OC_ISO="$CACHE_DIR/opencore-osx-proxmox-vm.iso"

if [ -f "$OC_ISO" ] && [ -s "$OC_ISO" ]; then
  msg_ok "Using cached OpenCore ISO"
else
  rm -f "$OC_ISO"
  msg_info "Downloading OpenCore ISO"
  if ! curl -fSL -o "$OC_ISO" "$OC_URL"; then
    msg_error "Failed to download OpenCore ISO from $OC_URL"
    rm -f "$OC_ISO"
    exit 1
  fi
  msg_ok "Downloaded OpenCore ISO"
fi

# ── Download macOS recovery image ──
RECOVERY_RAW="$TEMP_DIR/recovery.img"
download_recovery "$MACOS_VER" "$RECOVERY_RAW"

# ── Build OpenCore GPT disk ──
OC_DISK="$TEMP_DIR/opencore.raw"
build_opencore_disk "$OC_ISO" "$OC_DISK" "$MACOS_VER"

# ── Generate SMBIOS identity ──
generate_smbios "$MACOS_VER"

# ── Create VM ──
msg_info "Creating macOS VM shell"
qm create "$VMID" \
  --name "$HN" \
  --ostype other \
  --machine q35 \
  --bios ovmf \
  --cores "$CORE_COUNT" \
  --memory "$RAM_SIZE" \
  --cpu host \
  --net0 "virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU" \
  --tags community-script \
  >/dev/null
msg_ok "Created VM shell"

# ── Apply macOS hardware profile ──
msg_info "Applying macOS hardware profile"
qm set "$VMID" \
  --args '-device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device qemu-xhci -device usb-kbd -device usb-tablet -global nec-usb-xhci.msi=off -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu host,kvm=on,vendor=GenuineIntel,+kvm_pv_unhalt,+kvm_pv_eoi,+hypervisor,+invtsc' \
  --vga std \
  --tablet 1 \
  --scsihw virtio-scsi-pci \
  >/dev/null
msg_ok "Applied hardware profile"

# ── Set SMBIOS identity (base64-encoded for Proxmox) ──
msg_info "Setting SMBIOS identity"
SMBIOS_MFR_B64=$(echo -n "Apple Inc." | base64)
SMBIOS_PRODUCT_B64=$(echo -n "$SMBIOS_MODEL" | base64)
SMBIOS_FAMILY_B64=$(echo -n "Mac" | base64)
qm set "$VMID" \
  --smbios1 "uuid=${SMBIOS_UUID},serial=${SMBIOS_SERIAL},base64=1,manufacturer=${SMBIOS_MFR_B64},product=${SMBIOS_PRODUCT_B64},family=${SMBIOS_FAMILY_B64}" \
  >/dev/null
msg_ok "Set SMBIOS identity (serial: $SMBIOS_SERIAL)"

# ── Attach EFI disk ──
msg_info "Attaching EFI disk"
qm set "$VMID" \
  --efidisk0 "${STORAGE}:0,efitype=4m,pre-enrolled-keys=0" \
  >/dev/null
msg_ok "Attached EFI disk"

# ── Create main disk ──
msg_info "Creating main disk (${DISK_SIZE})"
qm set "$VMID" --sata0 "${STORAGE}:${DISK_SIZE%G}" >/dev/null
msg_ok "Created main disk"

# ── Detect import command (PVE 8.x vs 9.x) ──
if qm disk import --help >/dev/null 2>&1; then
  IMPORT_CMD=(qm disk import)
else
  IMPORT_CMD=(qm importdisk)
fi

# Helper: extract disk ref from import output, with fallback
# Args: $1=import_output $2=storage $3=vmid $4=label
function get_disk_ref() {
  local import_out="$1" storage="$2" vmid="$3" label="$4"
  local ref
  ref="$(printf '%s\n' "$import_out" | sed -n "s/.*successfully imported disk '\([^']\+\)'.*/\1/p" | tr -d "\r\"'")"
  if [[ -z "$ref" ]]; then
    # Fallback: get the most recently created disk for this VM
    ref="$(pvesm list "$storage" --vmid "$vmid" 2>/dev/null | awk 'NR>1{print $1}' | sort | tail -n1)"
  fi
  if [[ -z "$ref" ]]; then
    msg_error "Unable to determine imported ${label} disk reference."
    echo "$import_out"
    exit 1
  fi
  echo "$ref"
}

# ── Import and attach OpenCore disk → ide0 ──
msg_info "Importing OpenCore boot disk"
OC_IMPORT_OUT="$("${IMPORT_CMD[@]}" "$VMID" "$OC_DISK" "$STORAGE" --format raw 2>&1)" || {
  msg_error "Failed to import OpenCore disk"
  echo "$OC_IMPORT_OUT"
  exit 1
}
OC_DISK_REF="$(get_disk_ref "$OC_IMPORT_OUT" "$STORAGE" "$VMID" "OpenCore")"
qm set "$VMID" --ide0 "${OC_DISK_REF},media=disk" >/dev/null
msg_ok "Attached OpenCore disk (ide0)"

# ── Import and attach recovery disk → ide2 ──
msg_info "Importing macOS recovery disk"
REC_IMPORT_OUT="$("${IMPORT_CMD[@]}" "$VMID" "$RECOVERY_RAW" "$STORAGE" --format raw 2>&1)" || {
  msg_error "Failed to import recovery disk"
  echo "$REC_IMPORT_OUT"
  exit 1
}
REC_DISK_REF="$(get_disk_ref "$REC_IMPORT_OUT" "$STORAGE" "$VMID" "recovery")"
qm set "$VMID" --ide2 "${REC_DISK_REF},media=disk" >/dev/null
msg_ok "Attached recovery disk (ide2)"

# ── Set boot order ──
msg_info "Setting boot order"
qm set "$VMID" --boot order="ide2;sata0;ide0" >/dev/null
msg_ok "Set boot order (ide2 → sata0 → ide0)"

# ── VM description ──
DESCRIPTION=$(
  cat <<EOF
<div align='center'>
  <a href='https://Helper-Scripts.com' target='_blank' rel='noopener noreferrer'>
    <img src='https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png' alt='Logo' style='width:81px;height:112px;'/>
  </a>

  <h2 style='font-size: 24px; margin: 20px 0;'>${MACOS_LABELS[$MACOS_VER]} VM</h2>

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
qm set "$VMID" -description "$DESCRIPTION" >/dev/null
msg_ok "Created ${MACOS_LABELS[$MACOS_VER]} VM ${CL}${BL}(${HN})"

# ── Start VM ──
if [ "$START_VM" == "yes" ]; then
  msg_info "Starting macOS VM"
  # Clean up any stale swtpm processes for this VMID
  pkill -f "swtpm.*${VMID}" 2>/dev/null || true
  rm -f "/var/run/qemu-server/${VMID}.swtpm" "/var/run/qemu-server/${VMID}.swtpm.pid" 2>/dev/null
  sleep 1
  qm start "$VMID"
  msg_ok "Started macOS VM"
fi

post_update_to_api "done" 0
echo ""
msg_ok "Completed successfully!"
echo -e "\n${INFO}${YW}Next steps:${CL}"
echo -e "  1. Open the VM console (VM ${VMID} → Console)"
echo -e "  2. In OpenCore boot picker, select '${GN}macOS Base System${CL}'"
echo -e "  3. Use Disk Utility to erase the SATA disk as APFS"
echo -e "  4. Run 'Reinstall macOS' from the recovery menu"
echo -e ""
echo -e "  ${BL}Documentation: https://github.com/lucid-fabrics/osx-proxmox-next${CL}"
echo -e ""
