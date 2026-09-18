#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="Ubuntu"
APP_TYPE="vm"
NSAPP="ubuntu-vm"
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
var_os="ubuntu"
var_version="26.04"
THIN="discard=on,ssd=1,"
USE_CLOUD_INIT="no"


set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

vm_preflight

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR" >/dev/null

if [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
  var_version="${VM_OS_VERSION:-$var_version}"
elif vm_dialog radiolist "UBUNTU VERSION" "Choose the Ubuntu release to install" --cancel-button Exit-Script 13 60 4 \
  "26.04" "Ubuntu 26.04 LTS (Resolute)" ON \
  "25.04" "Ubuntu 25.04 (Plucky)" OFF \
  "24.04" "Ubuntu 24.04 LTS (Noble)" OFF \
  "22.04" "Ubuntu 22.04 LTS (Jammy)" OFF; then
  var_version="$VM_DIALOG_RESULT"
else
  exit_script
fi

case "$var_version" in
26.04) UBUNTU_CODENAME="resolute" ;;
25.04) UBUNTU_CODENAME="plucky" ;;
24.04) UBUNTU_CODENAME="noble" ;;
22.04) UBUNTU_CODENAME="jammy" ;;
*)
  msg_error "Unsupported Ubuntu version '${var_version}'"
  exit 1
  ;;
esac
APP="Ubuntu ${var_version} VM"

header_info
echo -e "\n Loading..."

# Ubuntu cloud images configure netplan from cloud-init only. Without it the
# guest boots with an interface that never gets an address.
VM_CLOUD_INIT="${VM_CLOUD_INIT:-yes}"
vm_prompt_cloud_init "ubuntu"
if [ "$USE_CLOUD_INIT" != "yes" ]; then
  msg_warn "Without Cloud-Init this Ubuntu image gets no network configuration - configure it in the guest yourself."
fi

function default_settings() {
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "q35"
  DISK_SIZE="7G"
  DISK_CACHE=""
  HN="ubuntu"
  CPU_TYPE=""
  CORE_COUNT="2"
  RAM_SIZE="2048"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  METHOD="default"

  echo -e "${CONTAINERID}${BOLD}${DGN}Virtual Machine ID: ${BGN}${VMID}${CL}"
  echo -e "${CONTAINERTYPE}${BOLD}${DGN}Machine Type: ${BGN}$(vm_machine_type_label "$MACHINE_TYPE")${CL}"
  echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}${DISK_SIZE}${CL}"
  echo -e "${DISKSIZE}${BOLD}${DGN}Disk Cache: ${BGN}None${CL}"
  echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}${HN}${CL}"
  echo -e "${OS}${BOLD}${DGN}CPU Model: ${BGN}$(vm_cpu_model_label)${CL}"
  echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}${RAM_SIZE}${CL}"
  echo -e "${CLOUD}${BOLD}${DGN}Cloud-Init: ${BGN}${USE_CLOUD_INIT}${CL}"
  echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}${BRG}${CL}"
  echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}${MAC}${CL}"
  echo -e "${VLANTAG}${BOLD}${DGN}VLAN: ${BGN}Default${CL}"
  echo -e "${DEFAULT}${BOLD}${DGN}Interface MTU Size: ${BGN}Default${CL}"
  echo -e "${GATEWAY}${BOLD}${DGN}Start VM when completed: ${BGN}${START_VM}${CL}"
  echo -e "${CREATING}${BOLD}${DGN}Creating a ${APP} using the above default settings${CL}"
}

function advanced_settings() {
  METHOD="advanced"
  echo -e "${CLOUD}${BOLD}${DGN}Cloud-Init: ${BGN}${USE_CLOUD_INIT}${CL}"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "${DISK_SIZE:-7G}" "Set Disk Size in GiB (e.g., 10, 20)"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "ubuntu"
  vm_prompt_cpu_model "kvm64"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "2048"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a ${APP}?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a ${APP} using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 2 CPU Cores\n• 2 GB RAM\n• 7 GB Disk" 13 58
post_to_api_vm

vm_select_storage "$HN"
vm_define_disk_references 2
DISK_IMPORT="-format ${DISK_IMPORT_FORMAT}"

msg_info "Retrieving the URL for the ${APP} Disk Image"
UBUNTU_ARCH="$(vm_arch_resolve amd64 arm64)"
URL="https://cloud-images.ubuntu.com/releases/server/${UBUNTU_CODENAME}/release/ubuntu-${var_version}-server-cloudimg-${UBUNTU_ARCH}.img"
sleep 2
msg_ok "${CL}${BL}${URL}${CL}"
CACHE_FILE="$(vm_image_cache_path "$URL")"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes $((100 * 1024 * 1024)) || exit 115
FILE="$(basename "$CACHE_FILE")"
# Work on a copy: vm_prepare_cloud_image rewrites hostname and machine-id into
# the image, which would poison the cache for every later VM.
cp -f "$CACHE_FILE" "$FILE"

vm_prepare_cloud_image "$FILE" "$HN" || true

msg_info "Creating a ${APP}"
qm create $VMID -agent 1${MACHINE} -tablet 0 -localtime 1 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
vm_alloc_efi_disk "$DISK0"
qm importdisk $VMID $FILE $STORAGE ${DISK_IMPORT:-} 1>&/dev/null
qm set $VMID \
  -efidisk0 ${DISK0_REF}${FORMAT} \
  -scsi0 ${DISK1_REF},${DISK_CACHE}${THIN}size=${DISK_SIZE} \
  -boot order=scsi0 \
  -serial0 socket >/dev/null
set_description

vm_resize_disk

if [ "$USE_CLOUD_INIT" = "yes" ] && declare -f setup_cloud_init >/dev/null 2>&1; then
  setup_cloud_init \
    "$VMID" \
    "$STORAGE" \
    "$HN" \
    "yes" \
    "${CLOUDINIT_USER:-ubuntu}" \
    "${CLOUDINIT_NETWORK_MODE:-dhcp}" \
    "${CLOUDINIT_IP:-}" \
    "${CLOUDINIT_GW:-}" \
    "${CLOUDINIT_DNS:-${CLOUDINIT_DNS_SERVERS:-1.1.1.1 8.8.8.8}}"

  if [[ "${CLOUDINIT_NETWORK_MODE:-dhcp}" == "static" ]]; then
    setup_cloud_init_network_no_rename \
      "$VMID" \
      "$MAC" \
      "$CLOUDINIT_IP" \
      "$CLOUDINIT_GW" \
      "${CLOUDINIT_DNS:-${CLOUDINIT_DNS_SERVERS:-1.1.1.1 8.8.8.8}}" \
      "${CLOUDINIT_SEARCH_DOMAIN:-local}"
  fi
fi

msg_ok "Created a ${APP} ${CL}${BL}(${HN})"
if [ "$START_VM" = "yes" ]; then
  msg_info "Starting ${APP}"
  $STD qm start $VMID
  msg_ok "Started ${APP}"
fi

post_update_to_api "done" "none"
msg_ok "Completed successfully!\n"
if [ "$USE_CLOUD_INIT" = "yes" ] && declare -f display_cloud_init_info >/dev/null 2>&1; then
  display_cloud_init_info "$VMID" "$HN"
else
  echo -e "Cloud-Init is disabled. The VM disk was resized on the Proxmox side only.\nIf the guest does not auto-expand its root filesystem after first boot, expand it manually inside the VM.\n\nMore info at https://github.com/community-scripts/ProxmoxVED/discussions/272 \n"
fi
