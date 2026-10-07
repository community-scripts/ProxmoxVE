#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
APP="Arch Linux"
APP_TYPE="vm"
NSAPP="archlinux-vm"
var_os="arch-linux"
var_version="n.d."

THIN="discard=on,ssd=1,"

header_info
echo -e "\n Loading..."
set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

vm_require_arch amd64

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

function default_settings() {
  vm_apply_machine_type "i440fx"
  VMID=$(get_valid_nextid)
  DISK_SIZE="10G"
  DISK_CACHE=""
  HN="arch-linux"
  CPU_TYPE=""
  CORE_COUNT="1"
  RAM_SIZE="1024"
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
  vm_prompt_machine_type "i440fx"
  vm_prompt_disk_size "10G"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "arch-linux"
  vm_prompt_cpu_model "kvm64"
  vm_prompt_cpu_cores "1"
  vm_prompt_ram "1024"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu

  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a Arch Linux VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a Arch Linux VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}


vm_preflight
vm_start_script "Use Default Settings?\n\nDefaults:\n• 1 CPU Core\n• 1 GB RAM\n• 10 GB Disk" 13 58
post_to_api_vm

vm_select_storage "$HN"
msg_info "Retrieving the URL for the Arch Linux .iso File"
URL=https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
FILENAME="archlinux-x86_64.iso"
CACHE_FILE="/var/lib/vz/template/iso/${FILENAME}"
mkdir -p "$(dirname "$CACHE_FILE")"
sleep 2
msg_ok "${CL}${BL}${URL}${CL}"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes $((100 * 1024 * 1024)) || exit 115

msg_info "Creating a Arch Linux VM"
qm create $VMID -agent 1${MACHINE} -tablet 0 -localtime 1 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-pci

qm set $VMID \
  -efidisk0 ${STORAGE}:0,efitype=4m \
  -scsi0 ${STORAGE}:${DISK_SIZE%G},${DISK_CACHE}${THIN%,} \
  -cdrom local:iso/${FILENAME} \
  -boot order='scsi0;ide2' \
  -serial0 socket >/dev/null
set_description

msg_ok "Created a Arch Linux VM ${CL}${BL}(${HN})"
if [ "$START_VM" == "yes" ]; then
  msg_info "Starting Arch Linux VM"
  $STD qm start $VMID
  msg_ok "Started Arch Linux VM"
fi
post_update_to_api "done" "none"

echo -e "\n${INFO}${BOLD}${GN}Arch Linux VM Configuration Summary:${CL}"
echo -e "${TAB}${DGN}VM ID: ${BGN}${VMID}${CL}"
echo -e "${TAB}${DGN}Hostname: ${BGN}${HN}${CL}"
echo -e "${TAB}${DGN}Disk Size: ${BGN}${DISK_SIZE}${CL}"

echo -e "\n${INFO}${BOLD}${YW}Next Steps:${CL}"
echo -e "${TAB}1. Open the VM Console in Proxmox - the live ISO logs in as root by itself"
echo -e "${TAB}2. Run ${BL}archinstall${CL}, or install by hand, onto ${BL}/dev/sda${CL}"
echo -e "${TAB}3. Detach the ISO afterwards (${BL}qm set ${VMID} --ide2 none${CL}) -- the boot"
echo -e "${TAB}   order already prefers the disk"
echo -e "${TAB}4. The ISO carries no Cloud-Init and no guest agent. Install"
echo -e "${TAB}   ${BL}qemu-guest-agent${CL} in the guest for Proxmox to show its IP"

msg_ok "Completed successfully!\n"
