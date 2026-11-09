#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: juronja
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.truenas.com/truenas-community-edition/

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
APP="TrueNAS"
APP_TYPE="vm"
NSAPP="truenas-vm"

header_info
echo -e "\n Loading..."

ISO="${TAB}📀${TAB}${CL}"
DISK="${TAB}💽${TAB}${CL}"

set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

function truenas_iso_lookup() {
  local BASE_URL="https://download.truenas.com"

  declare -A latest_stables
  local pre_releases=()
  local excluded_codenames="(Angelfish|Bluefin|Cobia|Dragonfish|ElectricEel|Fangtooth)"

  local all_paths=$(
    curl -fsSL "${_CS_CURL_RETRY[@]}" --max-time 90 "$BASE_URL" |
      grep -oE 'href="[^"]+\.iso"' |
      sed 's/href="//; s/"$//' |
      grep -vE '(MASTER|ALPHA)'
  )

  while read -r path; do
    [[ -n "$path" ]] || continue
    local filename=$(basename "$path")

    if [[ "$path" =~ $excluded_codenames ]]; then
      continue
    fi

    if [[ "$filename" =~ (RC|BETA) ]]; then
      if [[ "$path" =~ 25\.10-(BETA|RC) ]]; then
        continue
      fi

      if [[ "$path" =~ /(2[4-9]|[3-9][0-9]) ]] || [[ "$filename" =~ (2[4-9]|[3-9][0-9]) ]]; then
        pre_releases+=("$path")
      fi
      continue
    fi

    local version=$(echo "$filename" | sed -E 's/.*TrueNAS-(SCALE-|CORE-)?([0-9]{2}\.[0-9]{2}(\.[0-9]+)*)\.iso.*/\2/')
    [[ -z "$version" ]] && continue

    local major_version=$(echo "$version" | cut -d'.' -f1,2)
    local current_stored_path=${latest_stables["$major_version"]:-}

    if [[ -z "$current_stored_path" ]]; then
      latest_stables["$major_version"]="$path"
    else
      local stored_version=$(basename "$current_stored_path" | sed -E 's/.*TrueNAS-(SCALE-|CORE-)?([0-9]{2}\.[0-9]{2}(\.[0-9]+)*)\.iso.*/\2/')
      if printf '%s\n' "$version" "$stored_version" | sort -V | tail -n 1 | grep -q "$version"; then
        latest_stables["$major_version"]="$path"
      fi
    fi
  done <<<"$all_paths"

  for key in "${!latest_stables[@]}"; do
    echo "${latest_stables[$key]#/}"
  done | sort -V

  for pre in "${pre_releases[@]}"; do
    echo "${pre#/}"
  done | sort -V | uniq
}

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

function default_settings() {
  VMID=$(get_valid_nextid)
  ISO_DEFAULT="latest stable"
  vm_apply_machine_type "q35"
  DISK_SIZE="16G"
  DISK_CACHE=""
  HN="truenas"
  CPU_TYPE=" -cpu host"
  CORE_COUNT="2"
  RAM_SIZE="8192"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  IMPORT_DISKS="no"
  METHOD="default"
  echo -e "${ISO}${BOLD}${DGN}ISO Chosen: ${BGN}${ISO_DEFAULT}${CL}"
  vm_echo_default_settings
}

function advanced_settings() {
  METHOD="advanced"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "16G" "Set Disk Size in GiB (e.g., 16, 32)"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "truenas"
  vm_prompt_cpu_model "host"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "8192"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_verbose "no"

  if vm_dialog yesno "IMPORT ONBOARD DISKS" --defaultno "Would you like to import onboard disks?" 10 58; then
    IMPORT_DISKS="yes"
  else
    IMPORT_DISKS="no"
  fi
  echo -e "${DISK}${BOLD}${DGN}Import onboard disks: ${BGN}${IMPORT_DISKS}${CL}"

  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a TrueNAS VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a TrueNAS VM using the above advanced settings${CL}"
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

ISO_LIST=($(truenas_iso_lookup))

if [ ${#ISO_LIST[@]} -eq 0 ]; then
  msg_error "Could not find any TrueNAS ISOs."
  exit 115
fi

ISO_ARRAY=()
for iso in "${ISO_LIST[@]}"; do
  ISO_ARRAY+=("$iso" "")
done

SELECTED_ISO=$(whiptail --title "SELECT TRUENAS ISO" --menu "\nSelect the TrueNAS ISO version to install:\n" 20 78 10 "${ISO_ARRAY[@]}" 3>&1 1>&2 2>&3) || {
  msg_error "ISO selection cancelled."
  exit 0
}

if [ -z "$SELECTED_ISO" ]; then
  msg_error "No ISO selected."
  exit 0
fi

FULL_URL="https://download.truenas.com/${SELECTED_ISO#/}"
ISO_NAME=$(basename "$FULL_URL")
vm_select_iso_storage "$ISO_NAME" "$HN"
CACHE_FILE="$ISO_PATH"

msg_info "Retrieving the ISO for the TrueNAS Disk Image"
MIN_ISO_BYTES=$((500 * 1024 * 1024))
vm_fetch_image "$FULL_URL" "$CACHE_FILE" --cache --min-bytes "$MIN_ISO_BYTES" || exit 115

set -o pipefail
msg_info "Creating TrueNAS VM shell"
qm create "$VMID"${MACHINE} -bios ovmf -agent enabled=1 -tablet 0 -localtime 1${CPU_TYPE} \
  -cores "$CORE_COUNT" -memory "$RAM_SIZE" -balloon 0 -name "$HN" -tags community-script \
  -net0 "virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU" -onboot 1 -ostype l26 \
  -efidisk0 $STORAGE:1,efitype=4m,pre-enrolled-keys=0 -sata0 ${STORAGE}:${DISK_SIZE%G},${DISK_CACHE}ssd=1 \
  -scsihw virtio-scsi-single -cdrom "$ISO_VOLUME" -boot order='sata0;ide2' -vga virtio >/dev/null
msg_ok "Created VM shell"

if [ "$IMPORT_DISKS" == "yes" ]; then
  msg_info "Importing onboard disks"
  DISKARRAY=()
  SCSI_NR=0

  while read -r LSOUTPUT; do
    TRUNCATED="${LSOUTPUT:0:45}"
    if [ ${#LSOUTPUT} -gt 45 ]; then
      TRUNCATED="${TRUNCATED}..."
    fi
    DISKARRAY+=("$LSOUTPUT" "$TRUNCATED" "OFF")
  done < <(ls /dev/disk/by-id | grep -E '^ata-|^nvme-|^usb-' | grep -v 'part')

  vm_dialog checklist "SELECT DISKS TO IMPORT" --notags --cancel-button "Exit Script" \
    "\nSelect disk IDs to import. (Use Spacebar to select)\n" 20 58 10 "${DISKARRAY[@]}" || exit
  SELECTIONS=$(echo "$VM_DIALOG_RESULT" | tr -d '"')

  for SELECTION in $SELECTIONS; do
    ((++SCSI_NR))

    ID_SERIAL=$(udevadm info --query=property --value --property=ID_SERIAL_SHORT "/dev/disk/by-id/$SELECTION")
    ID_SERIAL=${ID_SERIAL:0:20}

    qm set $VMID --scsi$SCSI_NR /dev/disk/by-id/$SELECTION,serial=$ID_SERIAL
  done
  msg_ok "Disks imported successfully"
fi

set_description

sleep 3

msg_ok "Created a TrueNAS VM ${CL}${BL}(${HN})"
if [ "$START_VM" == "yes" ]; then
  msg_info "Starting TrueNAS VM"
  $STD qm start $VMID
  msg_ok "Started TrueNAS VM"
fi

msg_ok "Completed Successfully!\n"
