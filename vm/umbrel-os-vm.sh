#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
APP="Umbrel OS"
APP_TYPE="vm"
NSAPP="umbrel-os-vm"
var_os="umbrel-os"
var_version="n.d."

HA=$(echo "\033[1;34m")

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
  vm_apply_machine_type "q35"
  VMID=$(get_valid_nextid)
  DISK_SIZE="32G"
  HN="umbrelos"
  CPU_TYPE=""
  CORE_COUNT="2"
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
  vm_prompt_disk_size "32G"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "umbrelos"
  vm_prompt_cpu_model "kvm64"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "4096"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a Umbrel OS VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a Umbrel OS VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}


vm_preflight
vm_start_script "Use Default Settings?\n\nDefaults:\n• 2 CPU Cores\n• 4 GB RAM\n• 32 GB Disk" 13 58
post_to_api_vm

vm_select_storage "$HN"


msg_info "Retrieving the URL for the Umbrel OS installer ISO"
UMBREL_RELEASE="$(curl -fsSL --max-time 20 https://api.umbrel.com/latest-release 2>/dev/null |
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[[ -z "$UMBREL_RELEASE" ]] && UMBREL_RELEASE="latest"
var_version="$UMBREL_RELEASE"

URL="https://download.umbrel.com/release/${UMBREL_RELEASE}/umbrelos-amd64-usb-installer.iso"
# The upstream file name is the same for every release, so the version goes into
# the cached name -- otherwise the cache serves 1.7.4 to someone asking for 2.0.
ISO_NAME="umbrelos-${UMBREL_RELEASE}-amd64-usb-installer.iso"
CACHE_DIR="/var/lib/vz/template/iso"
CACHE_FILE="${CACHE_DIR}/${ISO_NAME}"
mkdir -p "$CACHE_DIR"
msg_ok "${CL}${BL}${URL}${CL}"

# download.umbrel.com answers 307 for any name at all, so a redirect proves
# nothing about the file existing. Size is what separates an ISO from a 404 page.
msg_info "Downloading the Umbrel OS installer ISO (approximately 1.8 GB)"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes $((1024 * 1024 * 1024)) || exit 115

msg_info "Creating a Umbrel OS VM"
# Umbrel requires EFI: the installer ISO has no legacy boot path. Its own
# console runs on tty1, so this VM is driven through noVNC, not the serial line.
qm create "$VMID"${MACHINE} -bios ovmf -agent enabled=1 -tablet 0 -localtime 1 ${CPU_TYPE} \
  -cores "$CORE_COUNT" -memory "$RAM_SIZE" -name "$HN" -tags community-script \
  -net0 "virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU" -onboot 1 -ostype l26 -scsihw virtio-scsi-pci \
  -efidisk0 "${STORAGE}:1,efitype=4m,pre-enrolled-keys=0" \
  -scsi0 "${STORAGE}:${DISK_SIZE%G},${DISK_CACHE:-}${THIN%,}" \
  -cdrom "local:iso/${ISO_NAME}" -boot order='scsi0;ide2' >/dev/null

set_description
msg_ok "Created a Umbrel OS VM ${CL}${BL}(${HN})"

if [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
  KEEP_IMAGE="${VM_KEEP_IMAGE:-yes}"
elif vm_dialog yesno "Image Cache" \
  "Keep downloaded Umbrel OS installer ISO for future VMs?\n\nFile: $CACHE_FILE" 10 70; then
  KEEP_IMAGE="yes"
else
  KEEP_IMAGE="no"
fi

if [[ "$KEEP_IMAGE" == "yes" ]]; then
  msg_ok "Keeping cached ISO"
else
  msg_warn "The ISO is still attached to the VM, so it is removed after the install"
  KEEP_IMAGE="no"
fi

if [ "$START_VM" == "yes" ]; then
  msg_info "Starting Umbrel OS VM"
  $STD qm start $VMID
  msg_ok "Started Umbrel OS VM"
fi
post_update_to_api "done" "none"

echo -e "\n${INFO}${BOLD}${YW}Next Steps:${CL}"
echo -e "${TAB}1. Open the VM console in Proxmox (noVNC)"
echo -e "${TAB}2. The installer asks which storage device to install umbrelOS on."
echo -e "${TAB}   Pick the ${BL}sda${CL} entry -- ${BL}sr0${CL} is the installer ISO itself"
echo -e "${TAB}3. Confirm, wait for it to finish, then press a key to power off"
echo -e "${TAB}4. Detach the ISO (${BL}qm set ${VMID} --ide2 none${CL}) and start the VM"
echo -e "${TAB}5. umbrelOS is then reachable at ${BL}http://umbrel.local${CL}"
if [[ "$KEEP_IMAGE" == "no" ]]; then
  echo -e "${TAB}   Delete ${BL}${CACHE_FILE}${CL} once the ISO is detached"
fi

msg_ok "Completed successfully!\n"
