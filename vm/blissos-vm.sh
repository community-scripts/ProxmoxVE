#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://blissos.org/

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="BlissOS"
APP_TYPE="vm"
NSAPP="blissos-vm"
var_os="android"
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
  DISK_SIZE="32G"
  DISK_CACHE=""
  HN="blissos"
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
  vm_prompt_disk_size "32G" "Set Disk Size in GiB"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "blissos"
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

  if vm_confirm_advanced_settings "Ready to create a BlissOS VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a BlissOS VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 4 CPU Cores (Host model)\n• 4 GB RAM\n• 32 GB Disk\n• Q35 Machine Type" 14 58
post_to_api_vm

vm_select_storage "$HN"

msg_info "Retrieving the URL for the BlissOS installer"

# The official x86 builds live under blissos-x86. Both blissos and blissos-dev
# also exist and are years out of date, which is an easy way to end up shipping
# a script that points at a 2020 image. BlissOS17 has directories but no builds
# in them, so BlissOS16 really is the newest branch with files.
#
# FOSS rather than Gapps by default: the same build without the Google apps,
# which also avoids redistributing those. The Gapps tree sits beside it.
ISO_DIR="https://sourceforge.net/projects/blissos-x86/files/Official/BlissOS16/FOSS/Generic"

# The build date orders these, not the version -- 16.9.7 exists more than once
# with different dates.
if ! vm_latest_from_index "${ISO_DIR}/" 'Bliss-v[0-9.]+-x86_64-OFFICIAL-foss-[0-9]{8}\.iso' --sort-by 'foss-\K[0-9]{8}'; then
  exit 1
fi

FILENAME="$VM_INDEX_LATEST"
BLISS_VERSION=$(echo "$FILENAME" | grep -oP 'Bliss-v\K[0-9.]+')
BLISS_BUILD=$(echo "$FILENAME" | grep -oP 'foss-\K[0-9]{8}')
var_version="${BLISS_VERSION}-${BLISS_BUILD}"
URL="${ISO_DIR}/${FILENAME}/download"
vm_select_iso_storage "$FILENAME" "$HN"
CACHE_FILE="$ISO_PATH"
msg_ok "BlissOS ${CL}${BL}${BLISS_VERSION}${CL} ${GN}(build ${BLISS_BUILD})"

# A bad SourceForge mirror serves an HTML notice with status 200, so the size
# decides whether this is an ISO, not curl's exit code. Learned from cachyos.
MIN_ISO_BYTES=$((1024 * 1024 * 1024))

[[ -s "$CACHE_FILE" ]] || msg_info "Downloading BlissOS (approximately 2 GB, this may take a while)"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes "$MIN_ISO_BYTES" || exit 115

msg_info "Creating a BlissOS VM"

# Android x86 carries virtio drivers -- the project targets QEMU as well as
# bare metal -- so unlike ChromeOS Flex this does not need SATA and e1000.
# UEFI with Secure Boot off; it will not boot with the Microsoft keys enrolled.
# virtio, not std: with stdvga Android gets as far as switch_root and then hangs
# on a black screen. vmwgfx does not help either; virtio-gpu is the DRM driver
# Android 13 actually carries. nomodeset also works but only until installation,
# since the installer writes its own bootloader config.
vm_claim_vmid
qm create $VMID -agent 1${MACHINE} -tablet 1 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 0 -ostype l26 -scsihw virtio-scsi-single \
  -efidisk0 ${STORAGE}:1,efitype=4m,pre-enrolled-keys=0 -scsi0 ${STORAGE}:${DISK_SIZE%G},${DISK_CACHE}${THIN%,} \
  -cdrom "$ISO_VOLUME" -boot order='scsi0;ide2' -vga virtio >/dev/null

vm_mark_created
set_description

msg_ok "Created a BlissOS VM ${CL}${BL}(${HN})"

vm_start_vm "BlissOS VM"
vm_print_summary "Version=${BLISS_VERSION} (build ${BLISS_BUILD})" "ISO=${FILENAME}"
vm_next_steps \
  "Open the VM Console in Proxmox." \
  "Pick Installation from the boot menu." \
  "Create and format a partition on sda, then install there." \
  "Say yes to GRUB and to a writable /system." \
  "Reboot; the boot order prefers the disk. Detach the ISO afterwards to tidy up." \
  "This is the FOSS build. Google apps are in the SourceForge BlissOS16/Gapps tree."
vm_finish "VM created; complete the BlissOS installation in the Proxmox console."
