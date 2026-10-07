#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/DevScripts/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

GEN_MAC=$(echo '00 60 2f'$(od -An -N3 -t xC /dev/urandom) | sed -e 's/ /:/g' | tr '[:lower:]' '[:upper:]')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
APP="MikroTik RouterOS"
APP_TYPE="vm"
NSAPP="mikrotik-routeros"
var_os="mikrotik"
var_version=" "
DISK_SIZE="1G"

THIN="discard=on,ssd=1,"

header_info
echo -e "Loading..."
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
  DISK_SIZE="8G"
  DISK_CACHE=""
  HN="mikrotik-routeros-chr"
  CPU_TYPE=""
  CORE_COUNT="2"
  RAM_SIZE="512"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  CLOUD_INIT="no"
  METHOD="default"
  vm_echo_default_settings
}

function get_mikrotik_version() {
  local mode="$1"
  local rss_url
  local tree_name

  case "$mode" in
  s) rss_url="https://cdn.mikrotik.com/routeros/latest-stable.rss" ;;
  d) rss_url="https://cdn.mikrotik.com/routeros/latest-development.rss" ;;
  l) rss_url="https://cdn.mikrotik.com/routeros/latest-long-term.rss" ;;
  t) rss_url="https://cdn.mikrotik.com/routeros/latest-testing.rss" ;;
  *) return 0 ;;
  esac

  local rss_content
  rss_content=$(curl -fsSL $rss_url 2>/dev/null)
  if [ -n "$rss_content" ]; then
    local version
    version=$(echo "$rss_content" | grep -oP '<title>RouterOS \K[0-9.]+(?= \[)' 2>/dev/null || echo "$rss_content" | sed -n 's/.*<title>RouterOS \([0-9.]\+\) \[.*/\1/p' 2>/dev/null)
    if [[ "$version" =~ ^[0-9]+\.[0-9]+ ]]; then
      echo "$version"
      return 0
    fi
  fi

  case "$mode" in
  s) tree_name="Stable release tree" ;;
  d) tree_name="Development release tree" ;;
  l) tree_name="Long-term release tree" ;;
  t) tree_name="Testing release tree" ;;
  esac

  local html
  html=$(curl -fsSL "https://mikrotik.com/download/changelogs" 2>/dev/null)
  if [ -n "$html" ]; then
    local start_line
    start_line=$(echo "$html" | grep -n "$tree_name" | cut -d: -f1 | head -n1)
    if [[ "$start_line" =~ ^[0-9]+$ ]]; then
      local line
      line=$(echo "$html" | tail -n +"$start_line" | grep -m 1 -E "c-(stable|longTerm|testing|development)-v|RouterOS [0-9]+\.[0-9]+" 2>/dev/null)

      local version
      version=$(echo "$line" | sed -n 's/.*c-[^"]*-v\([0-9_.a-zA-Z-]\+\).*/\1/p' | tr '_' '.' 2>/dev/null)
      [ -z "$version" ] && version=$(echo "$line" | grep -oP 'RouterOS \K[0-9]+\.[0-9]+(\.[0-9]+)?' 2>/dev/null)

      if [[ "$version" =~ ^[0-9]+\.[0-9]+ ]]; then
        echo "$version"
        return 0
      fi
    fi
  fi

  for minor in $(seq 50 -1 15); do
    local test_version="7.${minor}"
    if curl -fsSL -I "https://download.mikrotik.com/routeros/${test_version}/chr-${test_version}.img.zip" 2>/dev/null | grep -q "200 OK"; then
      echo "$test_version"
      return 0
    fi
  done

  return 0
}

function advanced_settings() {
  METHOD="advanced"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "i440fx"
  vm_prompt_disk_size "8G"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "mikrotik-routeros-chr"
  vm_prompt_cpu_model "kvm64"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "512"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a MikroTik RouterOS VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a MikroTik RouterOS VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}


vm_preflight
vm_start_script "Use Default Settings?\n\nDefaults:\n• 2 CPU Cores\n• 512 MB RAM\n• 8 GB Disk" 13 58

post_to_api_vm
vm_select_storage "$HN"
msg_info "Getting URL for Latest Mikrotik RouterOS CHR Disk Image"

MIK_VER=$(get_mikrotik_version s)

if [ -n "$MIK_VER" ]; then
  msg_ok "Latest stable version: ${CL}${BL}$MIK_VER${CL}."
else
  msg_error "Could not get latest version"
  msg_ok "Defaulting to version 7.20"
  MIK_VER="7.20"
fi

URL=https://download.mikrotik.com/routeros/$MIK_VER/chr-$MIK_VER.img.zip

sleep 2
msg_ok "Downloading from URL: ${CL}${BL}${URL}${CL}"
# A mirror serving an error page returns 200, so size decides whether this
# is an image. Anything real here is far above 5 MB.
CACHE_FILE="$(vm_image_cache_path "$URL")"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes $((5 * 1024 * 1024)) || exit 115
msg_info "Extracting Mikrotik RouterOS CHR Disk Image"
# Decompress out of the cache rather than over it, gunzip eats its input.
FILE="$(basename "${CACHE_FILE%.zip}")"
gunzip -c -S .zip "$CACHE_FILE" >"$FILE"
STORAGE_TYPE=$(pvesm status -storage $STORAGE | awk 'NR>1 {print $2}')
case $STORAGE_TYPE in
nfs | dir)
  DISK_EXT=".qcow2"
  DISK_REF="$VMID/"
  DISK_IMPORT="-format qcow2"
  ;;
btrfs)
  DISK_EXT=".raw"
  DISK_REF="$VMID/"
  DISK_IMPORT="-format raw"
  ;;
zfspool)
  DISK_EXT=""
  DISK_REF=""
  DISK_IMPORT="-format raw"
  ;;
*)
  DISK_EXT=""
  DISK_REF=""
  DISK_IMPORT="-format raw"
  ;;
esac

DISK_VAR="vm-${VMID}-disk-0${DISK_EXT:-}"
DISK_REF="${STORAGE}:${DISK_REF:-}${DISK_VAR:-}"

msg_ok "Extracted Mikrotik RouterOS CHR Disk Image"
msg_info "Creating Mikrotik RouterOS CHR VM"
qm create $VMID -tablet 0 -localtime 1 -cores $CORE_COUNT -memory $RAM_SIZE -name $HN \
  -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU \
  -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
qm importdisk $VMID "$FILE" $STORAGE ${DISK_IMPORT:-} 1>&/dev/null
qm set $VMID \
  -scsi0 "$DISK_REF" \
  -boot order=scsi0 >/dev/null

set_description
vm_resize_disk

msg_ok "Mikrotik RouterOS CHR VM ${CL}${BL}(${HN})"
if [ "$START_VM" == "yes" ]; then
  msg_info "Starting Mikrotik RouterOS CHR VM"
  $STD qm start $VMID
  msg_ok "Started Mikrotik RouterOS CHR VM"
fi
post_update_to_api "done" "none"
msg_ok "Completed successfully!\n"
