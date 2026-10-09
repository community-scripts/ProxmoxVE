#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
APP="Nextcloud"
APP_TYPE="vm"
NSAPP="nextcloud-vm"
var_os="turnkey-nextcloud"
var_version="19.0"

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

function default_settings() {
  vm_apply_machine_type "i440fx"
  VMID=$(get_valid_nextid)
  DISK_SIZE="10G"
  DISK_CACHE=""
  HN="nextcloud-vm"
  CPU_TYPE=""
  CORE_COUNT="2"
  RAM_SIZE="2048"
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
  vm_prompt_hostname "nextcloud-vm"
  vm_prompt_cpu_model "kvm64"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "2048"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_keyboard
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a Nextcloud VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a Nextcloud VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_preflight
vm_start_script "Use Default Settings?\n\nDefaults:\n• 2 CPU Cores\n• 2 GB RAM\n• 10 GB Disk" 13 58

post_to_api_vm

vm_select_storage "$HN"
msg_info "Retrieving the ${APP} installer ISO"
URL=https://mirror.turnkeylinux.org/turnkeylinux/images/iso/turnkey-nextcloud-19.0-trixie-amd64.iso
sleep 2
msg_ok "${CL}${BL}${URL}${CL}"
vm_select_iso_storage "$(basename "$URL")" "$HN"
vm_fetch_image "$URL" "$ISO_PATH" --cache --min-bytes $((100 * 1024 * 1024)) || exit 115

vm_claim_vmid
msg_info "Creating a ${APP}"
qm create $VMID -agent 1${MACHINE} -tablet 0 -bios seabios${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-pci \
  -scsi0 "${STORAGE}:${DISK_SIZE%G},${DISK_CACHE}${THIN%,}" \
  -cdrom "$ISO_VOLUME" -boot order='scsi0;ide2' >/dev/null
vm_mark_created
set_description

msg_ok "Created a ${APP} ${CL}${BL}(${HN})"
vm_start_vm "$APP"
vm_print_summary "Version=TurnKey Nextcloud ${var_version}" "Installer=$(basename "$URL")" "Web UI=https://<VM-IP>/" "Webmin=https://<VM-IP>:12321/"
vm_next_steps \
  "Open the VM Console in Proxmox and complete the TurnKey installer." \
  "Set the root, Nextcloud admin, and database credentials when prompted." \
  "After installation, detach the ISO: qm set ${VMID} --ide2 none." \
  "Start or reboot the VM, then open https://<VM-IP>/ for Nextcloud." \
  "Manage the appliance through Webmin at https://<VM-IP>:12321/."
vm_finish "VM created; complete the TurnKey Nextcloud installation in the Proxmox console."
