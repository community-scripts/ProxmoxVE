#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
APP="Home Assistant OS"
APP_TYPE="vm"
NSAPP="haos-vm"
var_os="homeassistant"
DISK_SIZE="32G"

for channel in stable beta dev; do
  channel_version=$(curl -fsSL "https://raw.githubusercontent.com/home-assistant/version/master/${channel}.json" | grep '"ova"' | cut -d '"' -f 4) || channel_version=""
  printf -v "$channel" '%s' "$channel_version"
done
if [ -z "$stable" ]; then
  echo -e "Could not determine the current Home Assistant OS release."
  exit 1
fi
beta="${beta:-$stable}"
dev="${dev:-$stable}"
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

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

function default_settings() {
  BRANCH="$stable"
  var_version="${BRANCH}"
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "q35"
  DISK_SIZE="32G"
  DISK_CACHE=""
  HN="homeassistant"
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
  if vm_dialog radiolist "Homeassistant OS Version" --cancel-button Exit-Script "Choose Version" 10 58 3 \n    "$stable" "Stable  " ON \n    "$beta" "Beta  " OFF \n    "$dev" "Dev  " OFF; then
    BRANCH="$VM_DIALOG_RESULT"
    var_version="${BRANCH}"
    echo -e "${DGN}Using HAOS Version: ${BGN}$BRANCH${CL}"
  else
    exit_script
  fi

  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "$DISK_SIZE" "Set Disk Size in GiB (e.g., 10, 20)"
  vm_prompt_disk_cache "writethrough"
  vm_prompt_hostname "homeassistant"
  vm_prompt_cpu_model "kvm64"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "4096"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create Homeassistant OS ${BRANCH} VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a Homeassistant OS VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}


vm_preflight
vm_start_script "Use Default Settings?" 10 58
post_to_api_vm

vm_select_storage "$HN"

var_version="${BRANCH}"
msg_info "Retrieving the URL for Home Assistant ${BRANCH} Disk Image"
if [ "$BRANCH" == "$dev" ]; then
  URL="https://os-artifacts.home-assistant.io/${BRANCH}/haos_ova-${BRANCH}.qcow2.xz"
else
  URL="https://github.com/home-assistant/operating-system/releases/download/${BRANCH}/haos_ova-${BRANCH}.qcow2.xz"
fi

CACHE_FILE="$(vm_image_cache_path "$URL")"
msg_ok "${CL}${BL}${URL}${CL}"

vm_fetch_image "$URL" "$CACHE_FILE" --cache --verify-xz || exit 115

msg_info "Creating Home Assistant OS VM shell"
qm create $VMID${MACHINE} -bios ovmf -agent 1 -tablet 0 -localtime 1 ${CPU_TYPE} \
  -cores "$CORE_COUNT" -memory "$RAM_SIZE" -name "$HN" -tags community-script \
  -net0 "virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU" -onboot 1 -ostype l26 -scsihw virtio-scsi-pci >/dev/null
msg_ok "Created VM shell"

vm_extract_image "$CACHE_FILE" || exit 115
FILE_IMG="$VM_IMAGE_FILE"

msg_info "Importing disk into storage ($STORAGE)"
if qm disk import --help >/dev/null 2>&1; then
  IMPORT_CMD=(qm disk import)
else
  IMPORT_CMD=(qm importdisk)
fi
IMPORT_OUT="$("${IMPORT_CMD[@]}" "$VMID" "$FILE_IMG" "$STORAGE" --format raw 2>&1 || true)"
DISK_REF="$(printf '%s\n' "$IMPORT_OUT" | sed -n "s/.*successfully imported disk '\([^']\+\)'.*/\1/p" | tr -d "\r\"'")"
[[ -z "$DISK_REF" ]] && DISK_REF="$(pvesm list "$STORAGE" | awk -v id="$VMID" '$5 ~ ("vm-"id"-disk-") {print $1":"$5}' | sort | tail -n1)"
[[ -z "$DISK_REF" ]] && {
  msg_error "Unable to determine imported disk reference."
  echo "$IMPORT_OUT"
  exit 226
}
msg_ok "Imported disk (${CL}${BL}${DISK_REF}${CL})"

rm -f "$FILE_IMG"

msg_info "Attaching EFI and root disk"
qm set $VMID \
  --efidisk0 ${STORAGE}:0,efitype=4m \
  --scsi0 ${DISK_REF},ssd=1,discard=on \
  --boot order=scsi0 \
  --serial0 socket >/dev/null
qm set $VMID --agent enabled=1 >/dev/null
msg_ok "Attached EFI and root disk"

vm_resize_disk

set_description
msg_ok "Created Homeassistant OS VM ${CL}${BL}(${HN})"

if [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
  KEEP_IMAGE="${VM_KEEP_IMAGE:-yes}"
elif vm_dialog yesno "Image Cache" \
  "Keep downloaded Home Assistant OS image for future VMs?\n\nFile: $CACHE_FILE" 10 70; then
  KEEP_IMAGE="yes"
else
  KEEP_IMAGE="no"
fi

if [[ "$KEEP_IMAGE" == "yes" ]]; then
  msg_ok "Keeping cached image"
else
  rm -f "$CACHE_FILE"
  msg_ok "Deleted cached image"
fi

if [ "$START_VM" == "yes" ]; then
  msg_info "Starting Home Assistant OS VM"
  $STD qm start $VMID
  msg_ok "Started Home Assistant OS VM"
fi
post_update_to_api "done" "none"
msg_ok "Completed successfully!\n"
