#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="Debian"
APP_TYPE="vm"
NSAPP="debian-vm"
var_os="debian"
var_version="13"
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""


THIN="discard=on,ssd=1,"
set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

vm_preflight

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

if [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
  var_version="${VM_OS_VERSION:-$var_version}"
elif vm_dialog radiolist "DEBIAN VERSION" "Choose the Debian release to install" --cancel-button Exit-Script 12 58 3 \
  "13" "Debian 13 (Trixie)" ON \
  "12" "Debian 12 (Bookworm)" OFF \
  "11" "Debian 11 (Bullseye)" OFF; then
  var_version="$VM_DIALOG_RESULT"
else
  exit_script
fi

case "$var_version" in
13) DEBIAN_CODENAME="trixie" ;;
12) DEBIAN_CODENAME="bookworm" ;;
11) DEBIAN_CODENAME="bullseye" ;;
*)
  msg_error "Unsupported Debian version '${var_version}'"
  exit 1
  ;;
esac
APP="Debian ${var_version}"

header_info
echo -e "\n Loading..."

# Asked here rather than inside advanced_settings: it picks the disk image, so a
# default-settings run has to answer it too. nocloud autologs in on the console
# and carries no cloud-init; genericcloud gets the full provisioning.
vm_prompt_cloud_init "debian"

function default_settings() {
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "q35"
  DISK_SIZE="8G"
  DISK_CACHE=""
  HN="debian"
  CPU_TYPE=""
  CORE_COUNT="2"
  RAM_SIZE="2048"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  METHOD="default"
  echo -e "${CLOUD}${BOLD}${DGN}Cloud-Init: ${BGN}${USE_CLOUD_INIT}${CL}"
  vm_echo_default_settings
}

function advanced_settings() {
  METHOD="advanced"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "8G"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "debian"
  vm_prompt_cpu_model "kvm64"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "2048"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu

  echo -e "${CLOUD}${BOLD}${DGN}Cloud-Init: ${BGN}${USE_CLOUD_INIT}${CL}"
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a ${APP} VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a ${APP} VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 2 CPU Cores\n• 2 GB RAM\n• 8 GB Disk" 13 58

post_to_api_vm

vm_select_storage "$HN"
msg_info "Retrieving the URL for the ${APP} Qcow2 Disk Image"
DEBIAN_ARCH="$(vm_arch_resolve amd64 arm64)"
if [ "$USE_CLOUD_INIT" == "yes" ]; then
  URL="https://cloud.debian.org/images/cloud/${DEBIAN_CODENAME}/latest/debian-${var_version}-genericcloud-${DEBIAN_ARCH}.qcow2"
else
  URL="https://cloud.debian.org/images/cloud/${DEBIAN_CODENAME}/latest/debian-${var_version}-nocloud-${DEBIAN_ARCH}.qcow2"
fi
sleep 2
msg_ok "${CL}${BL}${URL}${CL}"
CACHE_FILE="$(vm_image_cache_path "$URL")"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes $((100 * 1024 * 1024)) || exit 115
FILE="$(basename "$CACHE_FILE")"
# Work on a copy: vm_prepare_cloud_image rewrites hostname and machine-id into
# the image, which would poison the cache for every later VM.
cp -f "$CACHE_FILE" "$FILE"

# qm resize only grows the block device. Without cloud-init nothing grows the
# guest partition, so expand it offline first.
if [ "${USE_CLOUD_INIT:-no}" != "yes" ]; then
  msg_info "Expanding the root filesystem to ${DISK_SIZE}"
  vm_expand_image "$FILE" "$DISK_SIZE" || true
fi

vm_prepare_cloud_image "$FILE" "$HN" || true

STORAGE_TYPE=$(pvesm status -storage $STORAGE | awk 'NR>1 {print $2}')
case $STORAGE_TYPE in
nfs | dir)
  DISK_EXT=".qcow2"
  DISK_REF="$VMID/"
  DISK_IMPORT="-format qcow2"
  THIN=""
  ;;
btrfs)
  DISK_EXT=".raw"
  DISK_REF="$VMID/"
  DISK_IMPORT="-format raw"
  FORMAT=",efitype=4m"
  THIN=""
  ;;
*)
  DISK_EXT=""
  DISK_REF=""
  DISK_IMPORT="-format raw"
  ;;
esac
for i in {0,1}; do
  disk="DISK$i"
  eval DISK${i}=vm-${VMID}-disk-${i}${DISK_EXT:-}
  eval DISK${i}_REF=${STORAGE}:${DISK_REF:-}${!disk}
done

msg_info "Creating a ${APP} VM"
qm create $VMID -agent 1${MACHINE} -tablet 0 -localtime 1 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags community-script,debian${var_version} -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
vm_alloc_efi_disk "$DISK0"
qm importdisk $VMID ${FILE} $STORAGE ${DISK_IMPORT:-} 1>&/dev/null
# No cloudinit drive here: setup_cloud_init attaches it, and attaching it twice
# fails the second qm set, which takes the whole run down under errexit.
qm set $VMID \
  -efidisk0 ${DISK0_REF}${FORMAT} \
  -scsi0 ${DISK1_REF},${DISK_CACHE}${THIN}size=${DISK_SIZE} \
  -boot order=scsi0 \
  -serial0 socket >/dev/null
set_description
vm_resize_disk

if [ "$USE_CLOUD_INIT" == "yes" ] && declare -f setup_cloud_init >/dev/null 2>&1; then
  setup_cloud_init \
    "$VMID" \
    "$STORAGE" \
    "$HN" \
    "yes" \
    "${CLOUDINIT_USER:-debian}" \
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

msg_ok "Created a ${APP} VM ${CL}${BL}(${HN})"
if [ "$START_VM" == "yes" ]; then
  msg_info "Starting ${APP} VM"
  $STD qm start $VMID
  msg_ok "Started ${APP} VM"
fi

msg_ok "Completed successfully!\n"
if [ "$USE_CLOUD_INIT" == "yes" ] && declare -f display_cloud_init_info >/dev/null 2>&1; then
  display_cloud_init_info "$VMID" "$HN"
else
  echo -e "NoCloud image: the console autologs in as root and there is no Cloud-Init.\n"
fi
