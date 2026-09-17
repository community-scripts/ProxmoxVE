#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://alpinelinux.org/cloud/

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="Alpine"
APP_TYPE="vm"
NSAPP="alpine-vm"
var_os="alpine"
var_version=" "
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
THIN="discard=on,ssd=1,"

header_info
echo -e "\n Loading..."

set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR" >/dev/null

vm_preflight

function default_settings() {
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "q35"
  DISK_SIZE="8G"
  DISK_CACHE=""
  HN="alpine"
  CPU_TYPE=" -cpu host"
  CORE_COUNT="2"
  RAM_SIZE="1024"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  METHOD="default"
  USE_CLOUD_INIT="yes"
  vm_echo_default_settings
}

function advanced_settings() {
  METHOD="advanced"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "8G" "Set Disk Size in GiB"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "alpine"
  vm_prompt_cpu_model "host"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "1024"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_cloud_init "alpine"
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create an Alpine VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating an Alpine VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 2 CPU Cores\n• 1 GB RAM\n• 8 GB Disk\n• Cloud-Init enabled" 14 58
post_to_api_vm

vm_select_storage "$HN"

if ! command -v virt-customize &>/dev/null; then
  msg_info "Installing libguestfs-tools"
  $STD apt-get update
  $STD apt-get install -y libguestfs-tools
  msg_ok "Installed libguestfs-tools"
fi

msg_info "Retrieving the URL for the Alpine cloud image"

# Alpine publishes a bios and a uefi variant side by side. This script boots
# through OVMF, so picking the bios image would produce a VM that never starts.
# The release number and the -r revision both live in the filename, so the
# directory has to be listed rather than guessed.
CLOUD_DIR="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/cloud"
FILE=$(curl -fsSL "${CLOUD_DIR}/" 2>/dev/null | grep -oP 'href="\Kgeneric_alpine-[0-9.]+-x86_64-uefi-cloudinit-r[0-9]+\.qcow2(?=")' | sort -V | tail -1)
if [[ -z "$FILE" ]]; then
  msg_error "Could not determine the current Alpine cloud image"
  exit 1
fi

ALPINE_VERSION=$(echo "$FILE" | grep -oP 'generic_alpine-\K[0-9.]+')
msg_ok "Alpine ${CL}${BL}${ALPINE_VERSION}${CL} ${GN}(${FILE})"

URL="${CLOUD_DIR}/${FILE}"
CACHE_FILE="$(vm_image_cache_path "$URL")"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes $((5 * 1024 * 1024)) || exit 115

msg_info "Customizing ${FILE}"
WORK_FILE=$(mktemp --suffix=.qcow2)
cp "$CACHE_FILE" "$WORK_FILE"
popd >/dev/null
rm -rf "$TEMP_DIR"

# No systemctl and no SELinux here: Alpine runs OpenRC, and the cloud image
# already wires up the serial console through /etc/inittab.
vm_prepare_cloud_image "$WORK_FILE" "$HN" || true
msg_ok "Customized image"

STORAGE_TYPE=$(pvesm status -storage "$STORAGE" | awk 'NR>1 {print $2}')
vm_apply_storage_layout "$STORAGE_TYPE"
vm_define_disk_references 3

if [[ "$DISK_IMPORT_FORMAT" == "raw" ]]; then
  msg_info "Converting image to raw format"
  RAW_FILE=$(mktemp --suffix=.raw)
  qemu-img convert -f qcow2 -O raw "$WORK_FILE" "$RAW_FILE"
  rm -f "$WORK_FILE"
  WORK_FILE="$RAW_FILE"
  msg_ok "Converted image to raw format"
fi

msg_info "Creating an Alpine VM"
qm create "$VMID" -agent 1${MACHINE} -tablet 0 -localtime 1 -bios ovmf${CPU_TYPE} -cores "$CORE_COUNT" -memory "$RAM_SIZE" \
  -name "$HN" -tags community-script -net0 virtio,bridge="$BRG",macaddr="$MAC""$VLAN""$MTU" -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
pvesm alloc "$STORAGE" "$VMID" "$DISK0" 4M 1>&/dev/null
pvesm alloc "$STORAGE" "$VMID" "$DISK2" 4M 1>&/dev/null
qm importdisk "$VMID" "$WORK_FILE" "$STORAGE" -format "$DISK_IMPORT_FORMAT" 1>&/dev/null
qm set "$VMID" \
  -efidisk0 "${DISK0_REF}${FORMAT:-}" \
  -scsi0 "${DISK1_REF}",${DISK_CACHE}${THIN}size="${DISK_SIZE}" \
  -tpmstate0 "${DISK2_REF}",version=v2.0 \
  -boot order=scsi0 \
  -serial0 socket >/dev/null
set_description
rm -f "$WORK_FILE"
msg_ok "Created an Alpine VM ${CL}${BL}(${HN})"

vm_resize_disk

vm_provision "$VMID" || true

if [ "$START_VM" == "yes" ]; then
  msg_info "Starting Alpine VM"
  $STD qm start "$VMID"
  msg_ok "Started Alpine VM"
fi

post_update_to_api "done" "none"

echo -e "\n${INFO}${BOLD}${GN}Alpine VM Configuration Summary:${CL}"
echo -e "${TAB}${DGN}VM ID: ${BGN}${VMID}${CL}"
echo -e "${TAB}${DGN}Hostname: ${BGN}${HN}${CL}"
echo -e "${TAB}${DGN}Release: ${BGN}Alpine ${ALPINE_VERSION}${CL}"
if [ -n "${CLOUDINIT_CRED_FILE:-}" ]; then
  echo -e "${TAB}${DGN}Cloud-Init credentials: ${BGN}${CLOUDINIT_CRED_FILE}${CL}"
fi

echo -e "\n${INFO}${BOLD}${YW}Note:${CL}"
echo -e "${TAB}Alpine uses apk and OpenRC, not apt and systemd."
echo -e "${TAB}Enable a service with ${BL}rc-update add <service> default${CL}."

msg_ok "Completed successfully!\n"
