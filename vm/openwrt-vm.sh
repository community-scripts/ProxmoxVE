#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Jon Spriggs (jontheniceguy) | MickLesk (CanbiZ) 
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/DevScripts/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
APP="OpenWrt"
APP_TYPE="vm"
NSAPP="openwrt-vm"
var_os="openwrt"
var_version=" "
DISK_SIZE="1G"
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
GEN_MAC_LAN=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')

HA=$(echo "\033[1;34m")

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

vm_preflight
vm_require_tools gzip

function send_line_to_vm() {
  echo -e "${DGN}Sending line: ${YW}$1${CL}"
  for ((i = 0; i < ${#1}; i++)); do
    character=${1:i:1}
    case $character in
    " ") character="spc" ;;
    "-") character="minus" ;;
    "=") character="equal" ;;
    ",") character="comma" ;;
    ".") character="dot" ;;
    "/") character="slash" ;;
    "'") character="apostrophe" ;;
    ";") character="semicolon" ;;
    '\') character="backslash" ;;
    '`') character="grave_accent" ;;
    "[") character="bracket_left" ;;
    "]") character="bracket_right" ;;
    "_") character="shift-minus" ;;
    "+") character="shift-equal" ;;
    "?") character="shift-slash" ;;
    "<") character="shift-comma" ;;
    ">") character="shift-dot" ;;
    '"') character="shift-apostrophe" ;;
    ":") character="shift-semicolon" ;;
    "|") character="shift-backslash" ;;
    "~") character="shift-grave_accent" ;;
    "{") character="shift-bracket_left" ;;
    "}") character="shift-bracket_right" ;;
    "A") character="shift-a" ;;
    "B") character="shift-b" ;;
    "C") character="shift-c" ;;
    "D") character="shift-d" ;;
    "E") character="shift-e" ;;
    "F") character="shift-f" ;;
    "G") character="shift-g" ;;
    "H") character="shift-h" ;;
    "I") character="shift-i" ;;
    "J") character="shift-j" ;;
    "K") character="shift-k" ;;
    "L") character="shift-l" ;;
    "M") character="shift-m" ;;
    "N") character="shift-n" ;;
    "O") character="shift-o" ;;
    "P") character="shift-p" ;;
    "Q") character="shift-q" ;;
    "R") character="shift-r" ;;
    "S") character="shift-s" ;;
    "T") character="shift-t" ;;
    "U") character="shift-u" ;;
    "V") character="shift-v" ;;
    "W") character="shift-w" ;;
    "X") character="shift-x" ;;
    "Y") character="shift-y" ;;
    "Z") character="shift-z" ;;
    "!") character="shift-1" ;;
    "@") character="shift-2" ;;
    "#") character="shift-3" ;;
    '$') character="shift-4" ;;
    "%") character="shift-5" ;;
    "^") character="shift-6" ;;
    "&") character="shift-7" ;;
    "*") character="shift-8" ;;
    "(") character="shift-9" ;;
    ")") character="shift-0" ;;
    esac
    qm sendkey $VMID "$character"
  done
  qm sendkey $VMID ret
}

function validate_ip_octets() {
  local octet='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
  [[ "$1" =~ ^${octet}\.${octet}\.${octet}\.${octet}$ ]]
}

function prompt_router_input() {
  local var_name="$1" title="$2" prompt="$3" default_value="$4" value
  if vm_dialog inputbox "$title" "$prompt" 8 58 "$default_value" --cancel-button Exit-Script; then
    value="$VM_DIALOG_RESULT"
    [[ -n "$value" ]] || value="$default_value"
    printf -v "$var_name" '%s' "$value"
  else
    exit_script
  fi
}

function prompt_router_ip() {
  local var_name="$1" title="$2" prompt="$3" default_value="$4" label="$5" value
  prompt_router_input "$var_name" "$title" "$prompt" "$default_value"
  value="${!var_name}"
  if ! validate_ip_octets "$value"; then
    msg_error "Invalid ${label} format. Needs to be 0.0.0.0, was $value"
    exit 1
  fi
  echo -e "${DGN}Using ${label}: ${BGN}$value${CL}"
}

function prompt_router_mac() {
  local var_name="$1" title="$2" prompt="$3" default_value="$4" label="$5" value
  prompt_router_input "$var_name" "$title" "$prompt" "$default_value"
  value="${!var_name}"
  if ! validate_mac_address "$value"; then
    msg_error "Invalid ${label}: $value"
    exit 1
  fi
  echo -e "${DGN}Using ${label}: ${BGN}$value${CL}"
}

function prompt_router_vlan() {
  local var_name="$1" label_var="$2" title="$3" prompt="$4" default_value="$5" input_value
  while true; do
    prompt_router_input "$label_var" "$title" "$prompt" "$default_value"
    input_value="${!label_var}"
    if [ -z "$input_value" ] || [ "$input_value" = "Default" ]; then
      printf -v "$var_name" '%s' ""
      printf -v "$label_var" '%s' "Default"
      echo -e "${DGN}Using ${title}: ${BGN}Default${CL}"
      break
    fi
    if validate_vlan_tag "$input_value"; then
      printf -v "$var_name" '%s' ",tag=$input_value"
      echo -e "${DGN}Using ${title}: ${BGN}$input_value${CL}"
      break
    fi
    vm_dialog msgbox "INVALID INPUT" "VLAN must be a number between 1 and 4094, or leave blank for default." 8 58
  done
}

function prompt_router_mtu() {
  local input_value
  while true; do
    prompt_router_input "MTU_VALUE" "MTU SIZE" "Set Interface MTU Size (leave blank for default)" ""
    input_value="$MTU_VALUE"
    if [ -z "$input_value" ]; then
      MTU=""
      MTU_VALUE="Default"
      echo -e "${DGN}Using Interface MTU Size: ${BGN}Default${CL}"
      break
    fi
    if validate_mtu "$input_value"; then
      MTU=",mtu=$input_value"
      echo -e "${DGN}Using Interface MTU Size: ${BGN}$input_value${CL}"
      break
    fi
    vm_dialog msgbox "INVALID INPUT" "MTU Size must be a number between 576 and 65520, or leave blank for default." 8 58
  done
}

function default_settings() {
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "i440fx"
  HN="openwrt"
  CORE_COUNT="1"
  RAM_SIZE="256"
  CPU_TYPE=""
  DISK_CACHE=""
  BRG="vmbr0"
  LAN_BRG="vmbr0"
  MAC=$GEN_MAC
  LAN_MAC=$GEN_MAC_LAN
  VLAN=""
  LAN_VLAN=""
  LAN_IP_ADDR="192.168.1.1"
  LAN_NETMASK="255.255.255.0"
  MTU=""
  START_VM="yes"
  METHOD="default"
  DISK_SIZE="1G"
  echo -e "${CONTAINERID}${BOLD}${DGN}VMID: ${BGN}${VMID}${CL}"
  echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}${HN}${CL}"
  echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${RAMSIZE}${BOLD}${DGN}RAM: ${BGN}${RAM_SIZE}${CL}"
  echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}${DISK_SIZE}${CL}"
  echo -e "${BRIDGE}${BOLD}${DGN}WAN Bridge: ${BGN}${BRG}${CL}"
  echo -e "${BRIDGE}${BOLD}${DGN}LAN Bridge: ${BGN}${LAN_BRG}${CL}"
  echo -e "${MACADDRESS}${BOLD}${DGN}WAN MAC: ${BGN}${MAC}${CL}"
  echo -e "${MACADDRESS}${BOLD}${DGN}LAN MAC: ${BGN}${LAN_MAC}${CL}"
}

function advanced_settings() {
  METHOD="advanced"
  CPU_TYPE=""
  DISK_CACHE=""
  vm_apply_machine_type "i440fx"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_hostname "openwrt"
  vm_prompt_cpu_cores "1"
  vm_prompt_ram "256"
  vm_prompt_disk_size "1G"
  vm_prompt_keyboard
  vm_prompt_verbose "no"
  prompt_router_input "BRG" "WAN BRIDGE" "Set a WAN Bridge" "vmbr0"
  echo -e "${DGN}Using WAN Bridge: ${BGN}$BRG${CL}"
  prompt_router_input "LAN_BRG" "LAN BRIDGE" "Set a LAN Bridge" "vmbr0"
  echo -e "${DGN}Using LAN Bridge: ${BGN}$LAN_BRG${CL}"
  prompt_router_ip "LAN_IP_ADDR" "LAN IP ADDRESS" "Set a router IP" "${LAN_IP_ADDR:-192.168.1.1}" "LAN IP ADDRESS"
  prompt_router_ip "LAN_NETMASK" "LAN NETMASK" "Set a router netmask" "${LAN_NETMASK:-255.255.255.0}" "LAN NETMASK"
  prompt_router_mac "MAC" "WAN MAC ADDRESS" "Set a WAN MAC Address" "$GEN_MAC" "WAN MAC address"
  prompt_router_mac "LAN_MAC" "LAN MAC ADDRESS" "Set a LAN MAC Address" "$GEN_MAC_LAN" "LAN MAC address"
  prompt_router_vlan "VLAN" "VLAN1" "WAN VLAN" "Set a WAN Vlan (leave blank for default)" ""
  prompt_router_vlan "LAN_VLAN" "VLAN2" "LAN VLAN" "Set a LAN Vlan" "999"
  prompt_router_mtu
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create OpenWrt VM?"; then
    echo -e "${RD}Creating a OpenWrt VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 1 CPU Core\n• 256 MB RAM\n• 1 GB Disk" 13 58
post_to_api_vm

vm_select_storage "$HN"
msg_info "Getting URL for OpenWrt Disk Image"

vm_latest_from_index "https://openwrt.org" 'Current stable release - OpenWrt \K[0-9]+\.[0-9]+\.[0-9]+' || exit 115
var_version="$VM_INDEX_LATEST"
URL="https://downloads.openwrt.org/releases/$var_version/targets/x86/64/openwrt-$var_version-x86-64-generic-ext4-combined.img.gz"

msg_ok "${CL}${BL}${URL}${CL}"
# A mirror serving an error page returns 200, so size decides whether this
# is an image. Anything real here is far above 5 MB.
CACHE_FILE="$(vm_image_cache_path "$URL")"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes $((5 * 1024 * 1024)) || exit 115

FILE="$TEMP_DIR/$(basename "${CACHE_FILE%.gz}")"
vm_extract_image "$CACHE_FILE" "$FILE" || exit 115
FILE="$VM_IMAGE_FILE"

vm_claim_vmid
msg_info "Creating OpenWrt VM"
qm create $VMID -cores $CORE_COUNT -memory $RAM_SIZE -name $HN \
  -onboot 1 -ostype l26 -scsihw virtio-scsi-pci --tablet 0 >/dev/null
vm_mark_created
vm_import_disk "$VMID" "$FILE" "$STORAGE"

$STD qm set $VMID \
  -scsi0 "${VM_IMPORTED_DISK}" \
  -boot order=scsi0 \
  -tags community-script
msg_ok "Attached disk"

msg_info "Resizing disk to ${DISK_SIZE}"
qm disk resize "$VMID" scsi0 "${DISK_SIZE}" >/dev/null
msg_ok "Resized disk to ${DISK_SIZE}"

set_description
msg_ok "Created OpenWrt VM ${CL}${BL}(${HN})"

msg_info "Booting OpenWrt to configure its network interfaces"
$STD qm start $VMID
sleep 15
VM_STATE=""
for i in {1..30}; do
  if ! VM_STATE="$(qm status "$VMID" 2>&1)"; then
    msg_error "VM $VMID no longer exists: ${VM_STATE}"
    exit 226
  fi
  [[ "$VM_STATE" == *running* ]] && break
  sleep 1
done

if [[ "$VM_STATE" != *running* ]]; then
  msg_error "VM $VMID did not reach running state: ${VM_STATE}"
  exit 226
fi
sleep 5
msg_ok "OpenWrt is running"

msg_info "Configuring network interfaces in OpenWrt"
$STD send_line_to_vm ""
$STD send_line_to_vm "uci delete network.@device[0]"
$STD send_line_to_vm "uci set network.wan=interface"
$STD send_line_to_vm "uci set network.wan.device=eth1"
$STD send_line_to_vm "uci set network.wan.proto=dhcp"
$STD send_line_to_vm "uci delete network.lan"
$STD send_line_to_vm "uci set network.lan=interface"
$STD send_line_to_vm "uci set network.lan.device=eth0"
$STD send_line_to_vm "uci set network.lan.proto=static"
$STD send_line_to_vm "uci set network.lan.ipaddr=${LAN_IP_ADDR}"
$STD send_line_to_vm "uci set network.lan.netmask=${LAN_NETMASK}"
$STD send_line_to_vm "uci commit"
$STD send_line_to_vm "poweroff"
msg_ok "Network interfaces configured in OpenWrt"

msg_info "Waiting for OpenWrt to shut down"
for i in {1..60}; do
  VM_STATE="$(qm status "$VMID" 2>&1)" || break
  [[ "$VM_STATE" == *stopped* ]] && break
  sleep 2
done
if [[ "$VM_STATE" != *stopped* ]]; then
  msg_error "OpenWrt did not shut down: ${VM_STATE}"
  exit 226
fi
msg_ok "OpenWrt has shut down"

msg_info "Adding bridge interfaces on Proxmox side"
qm set $VMID \
  -net0 virtio,bridge=${LAN_BRG},macaddr=${LAN_MAC}${LAN_VLAN}${MTU} \
  -net1 virtio,bridge=${BRG},macaddr=${MAC}${VLAN}${MTU} >/dev/null
msg_ok "Bridge interfaces added"

if [ "$START_VM" = "yes" ]; then
  msg_info "Starting OpenWrt VM"
  $STD qm start $VMID
  msg_ok "Started OpenWrt VM"
fi

VLAN_FINISH=""
if [ -z "$VLAN" ] && [ "${VLAN2:-999}" != "999" ]; then
  VLAN_FINISH=" Please remember to adjust the VLAN tags to suit your network."
fi
vm_print_summary \
  "LAN URL=http://${LAN_IP_ADDR}" \
  "WAN Bridge=${BRG}" \
  "LAN Bridge=${LAN_BRG}" \
  "OpenWrt Version=${var_version}"
vm_next_steps \
  "Open the LAN web UI at http://${LAN_IP_ADDR}." \
  "Login as root with a blank initial password, then set a strong password immediately." \
  "Keep WAN and LAN isolated appropriately; the defaults put both on vmbr0 until you adjust bridges/VLANs.${VLAN_FINISH}"
vm_finish
