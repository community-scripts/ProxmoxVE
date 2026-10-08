#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/IceWhaleTech/ZimaOS

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="ZimaOS"
APP_TYPE="vm"
NSAPP="zimaos-vm"
var_os="zimaos"
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

function default_settings() {
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "q35"
  DISK_SIZE="64G"
  DISK_CACHE=""
  HN="zimaos"
  CPU_TYPE=" -cpu host"
  CORE_COUNT="4"
  RAM_SIZE="4096"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  METHOD="default"
  vm_echo_default_settings
}

function advanced_settings() {
  METHOD="advanced"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "64G" "Set Disk Size in GiB (Recommended: 64+ for apps)"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "zimaos"
  vm_prompt_cpu_model "host"
  vm_prompt_cpu_cores "4"
  vm_prompt_ram "4096"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_keyboard
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a ZimaOS VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a ZimaOS VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 4 CPU Cores (Host model)\n• 4 GB RAM\n• 64 GB Disk\n• Q35 Machine Type" 14 58
post_to_api_vm

vm_select_storage "$HN"

msg_info "Retrieving the URL for the ZimaOS installer"
if ! vm_release_asset github IceWhaleTech/ZimaOS 'zimaos-x86_64-.*_installer\.iso$'; then
  exit 1
fi
URL="$VM_RELEASE_URL"
FILENAME="$VM_RELEASE_ASSET"
ZIMAOS_VERSION="$VM_RELEASE_VERSION"
var_version="$ZIMAOS_VERSION"
vm_select_iso_storage "$FILENAME" "$HN"
CACHE_FILE="$ISO_PATH"
msg_ok "ZimaOS ${CL}${BL}${ZIMAOS_VERSION}${CL}"

[[ -s "$CACHE_FILE" ]] || msg_warn "Downloading the ZimaOS installer (approximately 2 GB, this may take a while)"
# Official installers such as 1.8.0-beta2 are smaller than 2 GiB.
MIN_ISO_BYTES=$((1024 * 1024 * 1024))
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes "$MIN_ISO_BYTES" --sha256 "$VM_RELEASE_SHA256" || exit 115

vm_claim_vmid
msg_info "Creating a ZimaOS VM"
$STD qm create $VMID -agent 1${MACHINE} -tablet 0 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-single \
  -efidisk0 ${STORAGE}:1,efitype=4m,pre-enrolled-keys=0 -scsi0 ${STORAGE}:${DISK_SIZE%G},${DISK_CACHE}${THIN%,} \
  -cdrom "$ISO_VOLUME" -boot order='scsi0;ide2' -vga std -serial0 socket
vm_mark_created
set_description
msg_ok "Created a ZimaOS VM ${CL}${BL}(${HN})"

vm_start_vm "ZimaOS VM"
vm_print_summary "Version=${ZIMAOS_VERSION}" "ISO=${FILENAME}" "Discovery=https://find.zimaspace.com"
vm_next_steps \
  "Open the VM Console in Proxmox." \
  "Follow the installer and select scsi0 as the target disk." \
  "When prompted to remove the disk and reboot, reboot; the boot order prefers the disk." \
  "Detach the ISO afterwards (Hardware -> CD/DVD -> Remove)." \
  "Read the IP from the Proxmox summary once the guest agent is up, or use https://find.zimaspace.com." \
  "For NAS use, add a second disk in Proxmox and let ZimaOS manage it."
vm_finish "VM created; complete the ZimaOS installation in the Proxmox console."
