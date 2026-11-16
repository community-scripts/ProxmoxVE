#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# ==============================================================================
# CachyOS VM - Creates a CachyOS Virtual Machine
# CachyOS is a performance-focused Arch Linux distribution with optimized
# packages, custom kernels, and various desktop environment options.
# ==============================================================================

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="CachyOS"
APP_TYPE="vm"
NSAPP="cachyos-vm"
var_os="cachyos"
var_version=" "
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
THIN="discard=on,ssd=1,"

header_info
echo -e "\n Loading..."

set -Eeo pipefail
shopt -s inherit_errexit
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

vm_require_arch amd64

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR" >/dev/null

vm_preflight

# ==============================================================================
# DEFAULT SETTINGS - Optimized for desktop usage with GUI
# ==============================================================================
function default_settings() {
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "q35"
  DISK_SIZE="40G"
  DISK_CACHE=""
  HN="cachyos"
  CPU_TYPE=" -cpu host"
  CORE_COUNT="4"
  RAM_SIZE="8192"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  METHOD="default"
  vm_echo_default_settings
}

# ==============================================================================
# ADVANCED SETTINGS
# ==============================================================================
function advanced_settings() {
  METHOD="advanced"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "40G" "Set Disk Size in GiB (Recommended: 40+ for desktop)"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "cachyos"
  vm_prompt_cpu_model "host"
  vm_prompt_cpu_cores "4"
  vm_prompt_ram "8192"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_keyboard
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a CachyOS VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a CachyOS VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
vm_start_script "Use Default Settings?\n\nDefaults:\n• 4 CPU Cores\n• 8 GB RAM\n• 40 GB Disk" 13 58
post_to_api_vm

vm_select_storage "$HN"

# ==============================================================================
# ISO DOWNLOAD
# ==============================================================================
msg_info "Retrieving the URL for the CachyOS Desktop ISO"

# Get latest release version from SourceForge (format: YYMMDD in folder links)
if ! vm_latest_from_index "https://sourceforge.net/projects/cachyos-arch/files/gui-installer/desktop/" 'desktop/\K[0-9]{6}(?=/)'; then
  exit 115
fi

CACHYOS_VERSION="$VM_INDEX_LATEST"
var_version="$CACHYOS_VERSION"

# SourceForge download URL with mirror redirect
URL="https://sourceforge.net/projects/cachyos-arch/files/gui-installer/desktop/${CACHYOS_VERSION}/cachyos-desktop-linux-${CACHYOS_VERSION}.iso/download"
FILENAME="cachyos-desktop-linux-${CACHYOS_VERSION}.iso"
vm_select_iso_storage "$FILENAME" "$HN"
CACHE_FILE="$ISO_PATH"
msg_ok "${CL}${BL}CachyOS Desktop ISO (Release: ${CACHYOS_VERSION})${CL}"

# A bad SourceForge mirror serves an HTML notice with status 200, so the size
# decides whether this is an ISO, not curl's exit code.
MIN_ISO_BYTES=$((500 * 1024 * 1024))

[[ -s "$CACHE_FILE" ]] || msg_info "Downloading the CachyOS ISO (approximately 3.1 GB, this may take a while)"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes "$MIN_ISO_BYTES" || exit 115

# ==============================================================================
# VM CREATION
# ==============================================================================
msg_info "Creating a CachyOS VM"

vm_claim_vmid
qm create $VMID -agent 1${MACHINE} -tablet 0 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 0 -ostype l26 -scsihw virtio-scsi-pci \
  -efidisk0 ${STORAGE}:1,efitype=4m,pre-enrolled-keys=0 -scsi0 ${STORAGE}:${DISK_SIZE%G},${DISK_CACHE}${THIN%,} \
  -cdrom "$ISO_VOLUME" -boot order='scsi0;ide2' -vga qxl -serial0 socket >/dev/null
vm_mark_created

set_description

msg_ok "Created a CachyOS VM ${CL}${BL}(${HN})"

# ==============================================================================
# START VM
# ==============================================================================
vm_start_vm "CachyOS VM"

# ==============================================================================
# FINAL OUTPUT
# ==============================================================================
vm_print_summary "Version=${CACHYOS_VERSION}" "ISO=${FILENAME}"
vm_next_steps \
  "Open the VM Console in Proxmox (noVNC or SPICE)." \
  "Boot from the CachyOS ISO." \
  "Use the Calamares installer to complete installation." \
  "Choose your preferred desktop environment during setup." \
  "After installation, detach the ISO; the boot order already prefers the disk."
vm_finish "VM created; complete the CachyOS installation in the Proxmox console."
