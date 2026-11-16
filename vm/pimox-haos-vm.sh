#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck | community-scripts ORG
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="Home Assistant OS (ARM64)"
APP_TYPE="vm"
NSAPP="pimox-haos-vm"
var_os="homeassistantos"
var_version=" "
var_arm64="yes"
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
METHOD=""
THIN="discard=on,ssd=1,"

header_info
echo -e "\n Loading..."

set -Eeo pipefail
shopt -s inherit_errexit
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"; exit 130' SIGINT
trap 'post_update_to_api "failed" "143"; exit 143' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

vm_require_arch arm64

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR" >/dev/null

vm_preflight
vm_require_tools jq xz

for channel in stable beta dev; do
  channel_version="$(curl -fsSL "https://raw.githubusercontent.com/home-assistant/version/master/${channel}.json" | jq -er '.hassos["generic-aarch64"]')"
  printf -v "${channel^^}" '%s' "$channel_version"
done

function default_settings() {
  METHOD="default"
  BRANCH="${VM_OS_VERSION:-$STABLE}"
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "virt"
  DISK_SIZE="32G"
  DISK_CACHE=""
  CPU_TYPE=""
  HN="haos"
  CORE_COUNT="2"
  RAM_SIZE="4096"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  vm_echo_default_settings
}

function advanced_settings() {
  METHOD="advanced"
  if [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
    BRANCH="${VM_OS_VERSION:-$STABLE}"
  elif vm_dialog radiolist "HAOS VERSION" "Choose Version" --cancel-button Exit-Script 12 58 3 \
    "$STABLE" "Stable" ON "$BETA" "Beta" OFF "$DEV" "Dev" OFF; then
    BRANCH="$VM_DIALOG_RESULT"
  else
    exit_script
  fi
  vm_apply_machine_type "virt"
  CPU_TYPE=""
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_disk_size "32G"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "haos"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "4096"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_keyboard
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"
  if ! vm_confirm_advanced_settings "Ready to create a HAOS VM?"; then
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 2 CPU Cores\n• 4 GB RAM\n• 32 GB Disk" 13 58
var_version="$BRANCH"
post_to_api_vm
vm_select_storage "$HN"
vm_define_disk_references 2

msg_info "Retrieving the Home Assistant OS ${BRANCH} image"
VM_RELEASE_SHA256=""
if [[ "$BRANCH" == "$DEV" ]]; then
  URL="https://os-artifacts.home-assistant.io/${BRANCH}/haos_generic-aarch64-${BRANCH}.qcow2.xz"
else
  if ! vm_release_asset github home-assistant/operating-system 'haos_generic-aarch64-.*\.qcow2\.xz$' "$BRANCH"; then
    exit 1
  fi
  URL="$VM_RELEASE_URL"
  var_version="$VM_RELEASE_VERSION"
fi
CACHE_FILE="$(vm_image_cache_path "$URL")"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --verify-xz --min-bytes $((5 * 1024 * 1024)) --sha256 "$VM_RELEASE_SHA256" || exit 115
vm_extract_image "$CACHE_FILE" "$TEMP_DIR/haos.qcow2"

vm_claim_vmid
msg_info "Creating HAOS VM"
qm create "$VMID"${MACHINE} -agent 1 -bios ovmf -cores "$CORE_COUNT" -memory "$RAM_SIZE" -name "$HN" \
  -net0 "virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU" -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
vm_mark_created
vm_alloc_efi_disk "$DISK0"
vm_import_disk "$VMID" "$VM_IMAGE_FILE" "$STORAGE"
qm set "$VMID" -efidisk0 "${DISK0_REF},efitype=4m,size=64M" \
  -scsi0 "${VM_IMPORTED_DISK},${DISK_CACHE}${THIN%,}" -boot order=scsi0 >/dev/null
vm_resize_disk
set_description

vm_start_vm "Home Assistant OS VM"
vm_print_summary "Version=${var_version}" "Web UI=http://<VM-IP>:8123" "Console=Native HAOS CLI (ha)"
vm_next_steps \
  "Wait several minutes for Home Assistant OS to finish first boot." \
  "Open http://<VM-IP>:8123 and complete onboarding." \
  "Use the Proxmox console for the native HAOS CLI (ha)." \
  "Cloud-Init credentials do not apply to this appliance."
vm_finish "HAOS VM created. Complete onboarding at http://<VM-IP>:8123 after first boot."
