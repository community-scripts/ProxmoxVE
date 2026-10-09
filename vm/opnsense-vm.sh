#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

#API VARIABLES
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
APP="OPNsense"
APP_TYPE="vm"
NSAPP="opnsense-vm"
var_os="opnsense"
var_version="26.7"
FREEBSD_MAJOR="15"
#
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
GEN_MAC_LAN=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')

HA=$(echo "\033[1;34m")
THIN="discard=on,ssd=1,"

header_info
echo -e "Loading..."
set -Eeo pipefail
shopt -s inherit_errexit
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

vm_require_arch amd64

function check_disk_space() {
  local path="$1"
  local required_gb="$2"
  local available_kb=$(df -k "$path" | awk 'NR==2 {print $4}')
  local available_gb=$((available_kb / 1024 / 1024))
  if [ $available_gb -lt $required_gb ]; then
    return 1
  fi
  return 0
}

TEMP_DIR=$(mktemp -d)
if ! check_disk_space "$TEMP_DIR" 20 && [ -d "/var/tmp" ] && check_disk_space "/var/tmp" 20; then
  rm -rf "$TEMP_DIR"
  TEMP_DIR=$(mktemp -d /var/tmp/opnsense-vm.XXXXXX)
fi
pushd "$TEMP_DIR" >/dev/null

vm_preflight
vm_require_tools xz

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

function get_available_bridges() {
  ip -o link show type bridge 2>/dev/null | awk -F': ' '{print $2}' | sort
}

function validate_ip_octets() {
  local octet='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
  [[ "$1" =~ ^${octet}\.${octet}\.${octet}\.${octet}$ ]]
}

function prompt_router_input() {
  local var_name="$1" title="$2" prompt="$3" default_value="$4" value
  if vm_dialog inputbox "$title" "$prompt" 8 58 "$default_value" --cancel-button Exit-Script; then
    value="$VM_DIALOG_RESULT"
    printf -v "$var_name" '%s' "$value"
  else
    exit_script
  fi
}

function prompt_optional_static_ip() {
  local ip_var="$1" gw_var="$2" mask_var="$3" prefix="$4" ip_value gw_value mask_value
  prompt_router_input "$ip_var" "${prefix} IP ADDRESS" "Set a ${prefix} IP" "${!ip_var:-}"
  ip_value="${!ip_var}"
  if [ -z "$ip_value" ]; then
    echo -e "${DGN}Using DHCP AS ${prefix} IP ADDRESS${CL}"
    return 0
  fi
  if ! validate_ip_octets "$ip_value"; then
    msg_error "Invalid IP Address format for ${prefix} IP. Needs to be 0.0.0.0, was $ip_value"
    exit 1
  fi
  echo -e "${DGN}Using ${prefix} IP ADDRESS: ${BGN}$ip_value${CL}"

  prompt_router_input "$gw_var" "${prefix} GATEWAY IP ADDRESS" "Set a ${prefix} GATEWAY IP" "${!gw_var:-}"
  gw_value="${!gw_var}"
  if [ -z "$gw_value" ]; then
    msg_error "${prefix} gateway is required for a static IP."
    exit 1
  fi
  if ! validate_ip_octets "$gw_value"; then
    msg_error "Invalid IP Address format for ${prefix} Gateway. Needs to be 0.0.0.0, was $gw_value"
    exit 1
  fi
  echo -e "${DGN}Using ${prefix} GATEWAY ADDRESS: ${BGN}$gw_value${CL}"

  prompt_router_input "$mask_var" "${prefix} NETMASK" "Set a ${prefix} netmask (24 for example)" "${!mask_var:-}"
  mask_value="${!mask_var}"
  if [ -z "$mask_value" ]; then
    msg_error "${prefix} netmask is required for a static IP."
    exit 1
  fi
  if [[ ! "$mask_value" =~ ^[0-9]+$ || "$mask_value" -lt 1 || "$mask_value" -gt 32 ]]; then
    msg_error "Invalid ${prefix} NETMASK format. Needs to be 1-32, was $mask_value"
    exit 1
  fi
  echo -e "${DGN}Using ${prefix} NETMASK: ${BGN}$mask_value${CL}"
}

function prompt_router_mac() {
  local var_name="$1" title="$2" prompt="$3" default_value="$4" label="$5" value
  prompt_router_input "$var_name" "$title" "$prompt" "$default_value"
  value="${!var_name}"
  [[ -n "$value" ]] || value="$default_value"
  printf -v "$var_name" '%s' "$value"
  if ! validate_mac_address "$value"; then
    msg_error "Invalid ${label}: $value"
    exit 1
  fi
  echo -e "${DGN}Using ${label}: ${BGN}$value${CL}"
}

function select_network_mode() {
  local available_bridges bridge_count default_wan_brg
  available_bridges=$(get_available_bridges)
  bridge_count=$(echo "$available_bridges" | wc -l)
  default_wan_brg=$(echo "$available_bridges" | grep -v "^${BRG}$" | head -n1 || true)

  if [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
    WAN_BRG="${VM_WAN_BRIDGE:-}"
  elif [ "$bridge_count" -ge 2 ]; then
    if vm_dialog radiolist "NETWORK CONFIGURATION" --cancel-button Exit-Script \
      "Choose network setup mode for OPNsense:\n" 14 70 2 \
      "dual" "Dual Interface (Firewall/Router) - uses ${default_wan_brg}" ON \
      "single" "Single Interface (Proxy/VPN/IDS Server)" OFF; then
      if [ "$VM_DIALOG_RESULT" = "dual" ]; then
        WAN_BRG="$default_wan_brg"
        echo -e "${DGN}Network Mode: ${BGN}Dual Interface (Firewall)${CL}"
        echo -e "${DGN}Using WAN Bridge: ${BGN}${WAN_BRG}${CL}"
        echo -e "${DGN}Using WAN MAC Address: ${BGN}${WAN_MAC}${CL}"
      else
        echo -e "${DGN}Network Mode: ${BGN}Single Interface (Proxy/VPN/IDS)${CL}"
        WAN_BRG=""
      fi
    else
      exit_script
    fi
  else
    echo -e "${DGN}Network Mode: ${BGN}Single Interface (Proxy/VPN/IDS)${CL}"
    echo -e "${YW}  (Only one bridge detected, dual interface requires a second bridge)${CL}"
    WAN_BRG=""
  fi
}

function prompt_wan_bridge() {
  local wan_bridges wan_menu=() first=true brg
  wan_bridges=$(get_available_bridges | grep -v "^${BRG}$" || true)
  if [ -z "$wan_bridges" ]; then
    WAN_BRG=""
    msg_warn "Only one bridge is available; using single-interface mode."
    return 0
  fi
  while IFS= read -r brg; do
    if $first; then
      wan_menu+=("$brg" "" "ON")
      first=false
    else
      wan_menu+=("$brg" "" "OFF")
    fi
  done <<<"$wan_bridges"

  if vm_dialog radiolist "WAN BRIDGE" "Select WAN Bridge" 14 58 6 "${wan_menu[@]}"; then
    WAN_BRG="$VM_DIALOG_RESULT"
    [[ -n "$WAN_BRG" ]] || WAN_BRG=$(echo "$wan_bridges" | head -n1)
    echo -e "${DGN}Using WAN Bridge: ${BGN}$WAN_BRG${CL}"
  else
    exit_script
  fi
}

function default_settings() {
  vm_apply_machine_type "i440fx"
  VMID=$(get_valid_nextid)
  DISK_SIZE="20G"
  FORMAT=",efitype=4m"
  MACHINE=""
  DISK_CACHE=""
  HN="opnsense"
  CPU_TYPE=""
  CORE_COUNT="4"
  RAM_SIZE="8192"
  BRG="vmbr0"
  IP_ADDR=""
  WAN_IP_ADDR=""
  LAN_GW=""
  WAN_GW=""
  NETMASK=""
  WAN_NETMASK=""
  VLAN=""
  MAC=$GEN_MAC
  WAN_MAC=$GEN_MAC_LAN
  WAN_BRG=""
  MTU=""
  START_VM="yes"
  METHOD="default"

  echo -e "${DGN}Using Virtual Machine ID: ${BGN}${VMID}${CL}"
  echo -e "${DGN}Using Hostname: ${BGN}${HN}${CL}"
  echo -e "${DGN}Allocated Cores: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${DGN}Allocated RAM: ${BGN}${RAM_SIZE}${CL}"
  if ! ip link show "${BRG}" &>/dev/null; then
    msg_error "Bridge '${BRG}' does not exist"
    exit
  else
    echo -e "${DGN}Using LAN Bridge: ${BGN}${BRG}${CL}"
  fi
  echo -e "${DGN}Using LAN VLAN: ${BGN}Default${CL}"
  echo -e "${DGN}Using LAN MAC Address: ${BGN}${MAC}${CL}"
  select_network_mode
  echo -e "${DGN}Using Interface MTU Size: ${BGN}Default${CL}"
  echo -e "${DGN}Start VM when completed: ${BGN}yes${CL}"
  echo -e "${BL}Creating a OPNsense VM using the above default settings${CL}"
}

function advanced_settings() {
  METHOD="advanced"
  IP_ADDR=""
  WAN_IP_ADDR=""
  LAN_GW=""
  WAN_GW=""
  NETMASK=""
  WAN_NETMASK=""
  VLAN=""
  MTU=""
  vm_prompt_disk_size "20G"
  vm_prompt_keyboard
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "i440fx"
  vm_prompt_cpu_model "kvm64"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "opnsense"
  vm_prompt_cpu_cores "4"
  vm_prompt_ram "8192"

  prompt_router_input "BRG" "LAN BRIDGE" "Set a LAN Bridge" "vmbr0"
  [[ -n "$BRG" ]] || BRG="vmbr0"
  if ! ip link show "${BRG}" &>/dev/null; then
    msg_error "Bridge '${BRG}' does not exist"
    exit 1
  fi
  echo -e "${DGN}Using LAN Bridge: ${BGN}$BRG${CL}"

  prompt_optional_static_ip "IP_ADDR" "LAN_GW" "NETMASK" "LAN"
  prompt_wan_bridge
  if [[ -n "$WAN_BRG" ]]; then
    prompt_optional_static_ip "WAN_IP_ADDR" "WAN_GW" "WAN_NETMASK" "WAN"
  fi
  prompt_router_mac "MAC" "LAN MAC ADDRESS" "Set a LAN MAC Address" "$GEN_MAC" "LAN MAC address"
  if [[ -n "$WAN_BRG" ]]; then
    prompt_router_mac "WAN_MAC" "WAN MAC ADDRESS" "Set a WAN MAC Address" "$GEN_MAC_LAN" "WAN MAC address"
  else
    WAN_MAC="$GEN_MAC_LAN"
  fi

  if vm_confirm_advanced_settings "Ready to create OPNsense VM?"; then
    echo -e "${RD}Creating a OPNsense VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 4 CPU Cores\n• 8 GB RAM\n• 20 GB Disk" 13 58
post_to_api_vm

vm_select_storage "$HN"
msg_ok "Virtual Machine ID is ${CL}${BL}$VMID${CL}."
msg_info "Retrieving the URL for the OPNsense Qcow2 Disk Image"
vm_latest_from_index "https://download.freebsd.org/releases/VM-IMAGES/" "${FREEBSD_MAJOR}\.[0-9]+-RELEASE" \
  --probe "https://download.freebsd.org/releases/VM-IMAGES/{}/amd64/Latest/FreeBSD-{}-amd64.qcow2.xz" \
  --probe "https://download.freebsd.org/releases/VM-IMAGES/{}/amd64/Latest/FreeBSD-{}-amd64-ufs.qcow2.xz" \
  --probe "https://download.freebsd.org/releases/VM-IMAGES/{}/amd64/Latest/FreeBSD-{}-amd64-zfs.qcow2.xz" || exit 115
FREEBSD_VER="$VM_INDEX_LATEST"
URL="$VM_INDEX_URL"
msg_ok "Download URL: ${CL}${BL}${URL}${CL}"

# Check available disk space (require at least 20GB for safety)
if ! check_disk_space "$TEMP_DIR" 20; then
  AVAILABLE_GB=$(df -h "$TEMP_DIR" | awk 'NR==2 {print $4}')
  msg_error "Insufficient disk space in temporary directory ($TEMP_DIR)."
  msg_error "Available: ${AVAILABLE_GB}, Required: ~20GB for FreeBSD image decompression."
  msg_error "Please free up space or ensure /tmp has sufficient storage."
  exit 214
fi

msg_info "Downloading FreeBSD Image"
# A mirror serving an error page returns 200, so size decides whether this
# is an image. Anything real here is far above 5 MB.
CACHE_FILE="$(vm_image_cache_path "$URL")"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --verify-xz --min-bytes $((5 * 1024 * 1024)) || exit 1
echo -en "\e[1A\e[0K"
msg_ok "Downloaded ${CL}${BL}$(basename "$CACHE_FILE")${CL}"

# Check disk space again before decompression
if ! check_disk_space "$TEMP_DIR" 15; then
  AVAILABLE_GB=$(df -h "$TEMP_DIR" | awk 'NR==2 {print $4}')
  msg_error "Insufficient disk space for decompression."
  msg_error "Available: ${AVAILABLE_GB}, Required: ~15GB for decompressed image."
  exit 214
fi

FILE="$TEMP_DIR/FreeBSD.qcow2"
vm_extract_image "$CACHE_FILE" "$FILE" || exit 115
FILE="$VM_IMAGE_FILE"

vm_define_disk_references 1

vm_claim_vmid
msg_info "Creating a OPNsense VM"
# A firewall VM filters itself: Proxmox's per-NIC firewall off, and virtio
# multiqueue matched to the cores so routing scales past one vCPU.
qm create $VMID -agent 1${MACHINE} -tablet 0 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE -balloon 0 \
  -name $HN -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC,firewall=0,queues=$CORE_COUNT$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
vm_mark_created

# Retry pvesm alloc on transient zfs_request "got timeout" errors (#14127)
alloc_attempt=1
alloc_max=4
alloc_delay=5
while :; do
  alloc_err=$(pvesm alloc $STORAGE $VMID $DISK0 4M 2>&1 >/dev/null) && break
  if [[ "$alloc_err" == *"got timeout"* && $alloc_attempt -lt $alloc_max ]]; then
    echo -e "${YW}[WARN]${CL} pvesm alloc hit zfs timeout (attempt $alloc_attempt/$alloc_max), retrying in ${alloc_delay}s..."
    pvesm free "${DISK0_REF}" &>/dev/null || true
    sleep "$alloc_delay"
    alloc_attempt=$((alloc_attempt + 1))
    alloc_delay=$((alloc_delay * 2))
    continue
  fi
  echo -e "$alloc_err" >&2
  exit 220
done
vm_import_disk "$VMID" "$FILE" "$STORAGE"
qm set $VMID \
  -efidisk0 ${DISK0_REF}${FORMAT} \
  -scsi0 "${VM_IMPORTED_DISK}",${DISK_CACHE}${THIN}size=2G \
  -boot order=scsi0 \
  -serial0 socket \
  -tags community-script >/dev/null
vm_resize_disk
set_description

msg_info "Bridge interfaces are being added."
qm set $VMID \
  -net0 virtio,bridge=${BRG},macaddr=${MAC},firewall=0,queues=${CORE_COUNT}${VLAN}${MTU} 2>/dev/null
if [ -n "$WAN_BRG" ]; then
  qm set $VMID \
    -net1 virtio,bridge=${WAN_BRG},macaddr=${WAN_MAC},firewall=0,queues=${CORE_COUNT} 2>/dev/null
fi
msg_ok "Bridge interfaces have been successfully added."

msg_ok "Created a OPNsense VM ${CL}${BL}(${HN})"
msg_ok "Starting OPNsense VM (the bootstrap takes 10-30 minutes)"
$STD qm start $VMID
sleep 90
send_line_to_vm "root"
sleep 2
send_line_to_vm ""
send_line_to_vm "for i in \$(seq 1 60); do fetch -q https://raw.githubusercontent.com/opnsense/update/master/src/bootstrap/opnsense-bootstrap.sh.in && break; sleep 5; done"
sleep 5
# FreeBSD 15+ VM images ship the base system as pkgbase packages; the bootstrap's
# "delete all packages" step would remove the running base system (/bin/rm etc.)
# and brick the VM. Deregister them from the pkg db first - the files stay in
# place and OPNsense replaces base and kernel with its own sets afterwards.
send_line_to_vm "echo \"PRAGMA foreign_keys=ON; DELETE FROM packages WHERE name LIKE 'FreeBSD-%';\" | pkg shell"
sleep 5
send_line_to_vm "sh ./opnsense-bootstrap.sh.in -y -f -r ${var_version}"
msg_ok "OPNsense VM is being installed, do not close the terminal, or the installation will fail."
# The bootstrap ends with an automatic reboot into OPNsense. While it runs the
# console keeps changing (download progress, package installs); once the VM has
# settled at the login prompt the screen stays static. Poll a screendump hash
# and continue after 3 minutes without change, bounded by a floor (the build
# never finishes faster) and a ceiling for slow machines. If no screendump can
# be captured at all, fall back to a fixed wait.
SCREEN_PPM="${TEMP_DIR}/screen-${VMID}.ppm"

function screen_hash() {
  # Remove the previous dump first: a stale file from an earlier successful
  # dump must not simulate a static screen when later dumps start failing.
  # Note: "qm monitor" is unusable here - its readline attaches to /dev/tty
  # even with piped stdin and captures the terminal, so use the API instead.
  rm -f "$SCREEN_PPM"
  timeout 10 pvesh create /nodes/$(hostname -s)/qemu/$VMID/monitor --command "screendump ${SCREEN_PPM}" >/dev/null 2>&1 || true
  md5sum "$SCREEN_PPM" 2>/dev/null | cut -d' ' -f1 || true
}

build_elapsed=300
build_stable=0
screen_ok=0
hash_a=""
hash_b=""
sleep 300
while [ $build_stable -lt 6 ] && [ $build_elapsed -lt 2400 ]; do
  sleep 30
  build_elapsed=$((build_elapsed + 30))
  new_hash=$(screen_hash)
  if [ -n "$new_hash" ]; then
    screen_ok=1
    # The login prompt cursor may blink: a screen alternating between the same
    # two frames (A/B/A/B) counts as stable, anything new resets the counter
    if [ "$new_hash" = "$hash_a" ] || [ "$new_hash" = "$hash_b" ]; then
      build_stable=$((build_stable + 1))
    else
      build_stable=0
    fi
  else
    build_stable=0
  fi
  hash_b="$hash_a"
  hash_a="$new_hash"
  if [ -n "$new_hash" ]; then
    echo -e "${DGN}Waiting for OPNsense build: ${YW}$((build_elapsed / 60))min elapsed, screen ${new_hash:0:8}, stable ${build_stable}/6${CL}"
  else
    echo -e "${DGN}Waiting for OPNsense build: ${YW}$((build_elapsed / 60))min elapsed, screendump failed${CL}"
  fi
  # No working screendump after several attempts: fixed wait instead
  if [ $screen_ok -eq 0 ] && [ $build_elapsed -ge 480 ]; then
    msg_warn "Console screendump not available on this system - falling back to a fixed wait (12 minutes)."
    sleep 720
    build_elapsed=$((build_elapsed + 720))
    break
  fi
done
if [ $build_stable -ge 6 ]; then
  msg_ok "OPNsense console settled after $((build_elapsed / 60)) minutes"
else
  msg_warn "The console did not settle within $((build_elapsed / 60)) minutes; continuing, verify the OPNsense console afterwards"
fi
# The answers below are matched to OPNsense's console dialog (setaddr.php).
# One prompt ("via WAN tracking?") only appears when WAN has DHCP6, so a spare
# "n" is sent for it; where it is absent, OPNsense re-asks the IPv6 address and
# the following ENTER lands there. Invalid answers are re-asked, empty ones take
# the default, which keeps the sequence safe in both dialog variants.
send_line_to_vm "root"
send_line_to_vm "opnsense"
send_line_to_vm "2"

if [ "$IP_ADDR" != "" ]; then
  send_line_to_vm "1"
  send_line_to_vm "n"
  send_line_to_vm "${IP_ADDR}"
  send_line_to_vm "${NETMASK}"
  send_line_to_vm "${LAN_GW}"
  send_line_to_vm "n"
  send_line_to_vm " "
  send_line_to_vm "n"
  send_line_to_vm "n"
  send_line_to_vm " "
  send_line_to_vm "n"
  send_line_to_vm "n"
  send_line_to_vm "n"
  send_line_to_vm "n"
  send_line_to_vm "n"
else
  send_line_to_vm "1"
  send_line_to_vm "y"
  send_line_to_vm "n"
  send_line_to_vm "n"
  send_line_to_vm " "
  send_line_to_vm "n"
  send_line_to_vm "n"
  send_line_to_vm "n"
fi
#Wait for config changes to be saved
sleep 20
if [ -n "$WAN_BRG" ] && [ "$WAN_IP_ADDR" != "" ]; then
  send_line_to_vm "2"
  send_line_to_vm "2"
  send_line_to_vm "n"
  send_line_to_vm "${WAN_IP_ADDR}"
  send_line_to_vm "${WAN_NETMASK}"
  send_line_to_vm "${WAN_GW}"
  send_line_to_vm "n"
  send_line_to_vm " "
  send_line_to_vm "n"
  send_line_to_vm " "
  send_line_to_vm "n"
  send_line_to_vm "n"
  send_line_to_vm "n"
fi
sleep 10
send_line_to_vm "0"
if [[ "$START_VM" == "no" ]]; then
  msg_info "Shutting down OPNsense as requested"
  $STD qm shutdown "$VMID" --timeout 120
  msg_ok "OPNsense VM shut down"
else
  msg_ok "OPNsense VM is running"
fi

if [ "$IP_ADDR" != "" ]; then
  LAN_URL="http://${IP_ADDR}"
else
  LAN_URL="DHCP - check the OPNsense console or your leases"
fi

vm_print_summary \
  "LAN URL=${LAN_URL}" \
  "LAN Bridge=${BRG}" \
  "WAN Bridge=${WAN_BRG:-single-interface mode}" \
  "OPNsense Version=${var_version}" \
  "FreeBSD Base=${FREEBSD_VER}"
vm_next_steps \
  "Verify the guest bootstrap and network configuration in the OPNsense console." \
  "Login as root with password opnsense after successful bootstrap, then change the password immediately." \
  "Keep WAN and LAN isolated appropriately; single-interface mode is intended for proxy, VPN, or IDS use cases."
vm_finish "VM creation completed; verify the guest bootstrap and network configuration in the console."
