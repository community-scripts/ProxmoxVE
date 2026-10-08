#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="UniFi OS Server"
APP_TYPE="vm"
NSAPP="unifi-os-server-vm"
var_os="debian"
var_version="13"
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
CLOUDINIT_REQUIRED=1
OS_TYPE=""
OS_VERSION=""
OS_CODENAME=""
OS_DISPLAY=""
THIN="discard=on,ssd=1,"

header_info
echo -e "\n Loading..."

set -Eeuo pipefail
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
vm_require_tools curl jq virt-customize

function select_os() {
  if [[ -n "${1:-}" ]]; then
    OS_CHOICE="$1"
  elif [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
    OS_CHOICE="${VM_OS_VERSION:-debian13}"
  elif vm_dialog radiolist "SELECT OS" "Choose Operating System for UniFi OS VM" 12 68 2 \
    "debian13" "Debian 13 (Trixie) - Latest" ON \
    "ubuntu2404" "Ubuntu 24.04 LTS (Noble)" OFF; then
    OS_CHOICE="$VM_DIALOG_RESULT"
  else
    exit_script
  fi

  case $OS_CHOICE in
  debian13)
    OS_TYPE="debian"
    OS_VERSION="13"
    OS_CODENAME="trixie"
    OS_DISPLAY="Debian 13 (Trixie)"
    var_os="debian"
    var_version="13"
    ;;
  ubuntu2404)
    OS_TYPE="ubuntu"
    OS_VERSION="24.04"
    OS_CODENAME="noble"
    OS_DISPLAY="Ubuntu 24.04 LTS"
    var_os="ubuntu"
    var_version="24.04"
    ;;
  *)
    msg_error "Unsupported OS '${OS_CHOICE}' (expected debian13 or ubuntu2404)"
    exit 1
    ;;
  esac
}

function get_image_url() {
  local arch
  arch=$(vm_arch_resolve amd64 arm64)
  case $OS_TYPE in
  debian)
    # Always use Cloud-Init variant for UniFi OS
    echo "https://cloud.debian.org/images/cloud/${OS_CODENAME}/latest/debian-${OS_VERSION}-generic-${arch}.qcow2"
    ;;
  ubuntu)
    # Ubuntu only has cloudimg variant (always with Cloud-Init support)
    echo "https://cloud-images.ubuntu.com/${OS_CODENAME}/current/${OS_CODENAME}-server-cloudimg-${arch}.img"
    ;;
  esac
}

function default_settings() {
  vm_apply_machine_type "q35"
  select_os "${VM_OS_VERSION:-}"

  # Set defaults for other settings
  VMID=$(get_valid_nextid)
  DISK_CACHE=""
  DISK_SIZE="32G"
  HN="unifi-server-os"
  CPU_TYPE=" -cpu host"
  CORE_COUNT="2"
  RAM_SIZE="6144"
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
  select_os
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "32G"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "unifi-server-os"
  vm_prompt_cpu_model "host"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "6144"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_keyboard
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a UniFi OS Server VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a UniFi OS Server VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 2 CPU Cores\n• 6 GB RAM\n• 32 GB Disk\n• Cloud-Init enabled" 14 58

if [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
  CLOUDINIT_PASSWORD="${CLOUDINIT_PASSWORD:-${VM_ROOT_PASSWORD:-}}"
fi
vm_prompt_cloud_init "root"
if [[ "${USE_CLOUD_INIT:-no}" != "yes" ]]; then
  msg_error "UniFi OS Server requires Cloud-Init"
  exit 1
fi
if ! declare -f setup_cloud_init >/dev/null; then
  msg_error "Required Cloud-Init helpers are unavailable"
  exit 1
fi
if [[ "${VM_UNATTENDED:-0}" == "1" && -n "${VM_SSH_KEYS:-}" && -z "${CLOUDINIT_SSH_KEYS:-}" ]]; then
  if [[ -f "$VM_SSH_KEYS" ]]; then
    cp "$VM_SSH_KEYS" "$TEMP_DIR/ssh-keys-input"
  else
    printf '%s\n' "$VM_SSH_KEYS" >"$TEMP_DIR/ssh-keys-input"
  fi
  CLOUDINIT_SSH_KEYS="$TEMP_DIR/ssh-keys.pub"
  _ci_ssh_extract_keys_from_file "$TEMP_DIR/ssh-keys-input" >"$CLOUDINIT_SSH_KEYS"
  if [[ ! -s "$CLOUDINIT_SSH_KEYS" ]] || ! ssh-keygen -lf "$CLOUDINIT_SSH_KEYS" >/dev/null; then
    msg_error "VM_SSH_KEYS must contain valid SSH public keys or name a public-key file"
    exit 1
  fi
fi

post_to_api_vm

msg_info "Checking system resources"
SYSTEM_RAM_GB=$(grep MemTotal /proc/meminfo | awk '{printf "%.0f", $2 / 1024 / 1024}')
SYSTEM_SWAP_GB=$(grep SwapTotal /proc/meminfo | awk '{printf "%.0f", $2 / 1024 / 1024}')
SYSTEM_FREE_DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [[ ${SYSTEM_RAM_GB} -lt 4 ]]; then
  msg_error "Warning: Less than 4GB RAM detected (${SYSTEM_RAM_GB}GB). Install may be slow."
  sleep 3
fi
if [[ ${SYSTEM_FREE_DISK_GB} -lt 10 ]]; then
  msg_error "Warning: Less than 10GB free disk detected. Install may fail."
  sleep 3
fi
msg_ok "System resources: ${SYSTEM_RAM_GB}GB RAM, ${SYSTEM_FREE_DISK_GB}GB free disk"

if command -v ufw &>/dev/null; then
  if ufw status verbose | grep -q "Status: active"; then
    msg_info "Setting up firewall rules for UniFi OS Server ports"
    ufw allow 11443/tcp 2>/dev/null
    ufw allow 8080/tcp 2>/dev/null
    ufw allow 3478/tcp 2>/dev/null
    ufw allow 3478/udp 2>/dev/null
    msg_ok "Firewall rules configured"
  fi
fi

vm_select_storage "$HN"

# Fetch latest UniFi OS Server version and download URL
msg_info "Fetching latest UniFi OS Server version"

# Download firmware list from Ubiquiti API
API_URL="https://fw-update.ui.com/api/firmware-latest"
TEMP_JSON=$(mktemp)

if ! curl -fsSL "$API_URL" -o "$TEMP_JSON"; then
  rm -f "$TEMP_JSON"
  msg_error "Failed to fetch data from Ubiquiti API"
  exit 1
fi

# Parse JSON to find latest unifi-os-server linux-x64 version
LATEST=$(jq -r '
  ._embedded.firmware
  | map(select(.product == "unifi-os-server"))
  | map(select(.platform == "linux-x64"))
  | sort_by(.version_major, .version_minor, .version_patch)
  | last
' "$TEMP_JSON")

UOS_VERSION=$(echo "$LATEST" | jq -r '.version' | sed 's/^v//')
UOS_URL=$(echo "$LATEST" | jq -r '._links.data.href')

# Cleanup temp file
rm -f "$TEMP_JSON"

if [[ -z "$UOS_URL" || "$UOS_URL" == "null" || -z "$UOS_VERSION" || "$UOS_VERSION" == "null" ]]; then
  msg_error "Failed to parse UniFi OS Server version or download URL"
  exit 1
fi

UOS_INSTALLER="unifi-os-server-${UOS_VERSION}.bin"
msg_ok "Found UniFi OS Server ${UOS_VERSION}"

# --- Download Cloud Image ---
msg_info "Downloading ${OS_DISPLAY} Cloud Image"
URL=$(get_image_url)
sleep 2
msg_ok "${CL}${BL}${URL}${CL}"
CACHE_FILE="$(vm_image_cache_path "$URL")"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes $((100 * 1024 * 1024)) || exit 115
FILE="$(basename "$CACHE_FILE")"
# Work on a copy: image preparation rewrites the image, which would poison the cache for every later VM.
cp -f "$CACHE_FILE" "$FILE"

# Resize the imported disk with vm_resize_disk; Cloud-Init grows the actual root
# filesystem before the first-boot installer runs, without another offline copy.

# --- Download UniFi OS installer on the host ---
msg_info "Downloading UniFi OS Server ${UOS_VERSION} installer"
curl -fsSL "${UOS_URL}" -o "unifi-os-server.bin"
chmod +x "unifi-os-server.bin"
msg_ok "Downloaded UniFi OS Server installer"

# --- Pre-install packages and setup first-boot installer ---
msg_info "Customizing disk image (installing packages, staging installer)"

# Create the first-boot installer script
FIRSTBOOT_SCRIPT="$TEMP_DIR/unifi-os-firstboot.sh"
cat >"$FIRSTBOOT_SCRIPT" <<'FBEOF'
#!/usr/bin/env bash
set -Eeuo pipefail
LOG="/var/log/unifi-os-install.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] Starting UniFi OS Server first-boot setup..."
trap 'echo "[$(date)] ERROR: First-boot setup failed at line $LINENO"' ERR
if ! systemctl start qemu-guest-agent; then
  echo "[$(date)] WARNING: Preinstalled guest agent could not start; retrying after package installation"
fi

# Sync clock before apt (fresh VMs have clock skew that breaks GPG signature validation)
echo "[$(date)] Syncing system clock..."
if ! timedatectl set-ntp true; then
  echo "[$(date)] WARNING: Could not enable NTP; checking existing clock synchronization"
fi
# Try NTP first
for attempt in {1..6}; do
  if timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -q "yes"; then
    echo "[$(date)] Clock synchronized via NTP"
    break
  fi
  sleep 5
done
# Fallback: sync from HTTP header if NTP didn't work
if ! timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -q "yes"; then
  if HTTP_DATE=$(curl -fsSI --max-time 10 https://deb.debian.org | sed -n 's/^[Dd]ate: //p' | tr -d '\r') &&
    [ -n "$HTTP_DATE" ] && date -s "$HTTP_DATE" >/dev/null; then
    echo "[$(date)] Clock synchronized via HTTP"
  else
    echo "[$(date)] WARNING: Clock synchronization unavailable"
  fi
fi

# Install required packages
export DEBIAN_FRONTEND=noninteractive
echo "[$(date)] Installing packages..."
for attempt in {1..3}; do
  if apt-get update -qq 2>&1; then
    break
  fi
  if [ "$attempt" -eq 3 ]; then
    echo "[$(date)] apt-get update failed after 3 attempts"
    exit 1
  fi
  echo "[$(date)] apt-get update failed (attempt $attempt/3), retrying in 10s..."
  sleep 10
done
for attempt in {1..3}; do
  if apt-get install -y -qq qemu-guest-agent podman uidmap slirp4netns curl wget; then
    break
  fi
  if [ "$attempt" -eq 3 ]; then
    echo "[$(date)] apt-get install failed after 3 attempts"
    exit 1
  fi
  echo "[$(date)] apt-get install failed (attempt $attempt/3), retrying in 10s..."
  sleep 10
done
systemctl enable --now qemu-guest-agent
echo "[$(date)] Packages installed"

# Setup swap (2GB)
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  echo "[$(date)] Swap file created"
fi

# Run UniFi OS installer
if [ -f /opt/unifi-os-server.bin ]; then
  cd /opt
  ./unifi-os-server.bin <<<'y'
  rm -f /opt/unifi-os-server.bin
  echo "[$(date)] UniFi OS Server installed successfully"
else
  echo "[$(date)] ERROR: /opt/unifi-os-server.bin not found"
  exit 1
fi

echo "[$(date)] First-boot setup complete"
FBEOF

vm_prepare_cloud_image "$FILE" "$HN"

vm_customize "UniFi OS installer" "$FILE" \
  --upload "unifi-os-server.bin:/opt/unifi-os-server.bin" \
  --chmod 0755:/opt/unifi-os-server.bin \
  --run-command "systemctl enable ssh" || exit 1

vm_firstboot_unit "$FILE" "unifi-os-firstboot" "$FIRSTBOOT_SCRIPT" \
  --description "UniFi OS Server First Boot Installer" \
  --after qemu-guest-agent.service \
  --requires-path /opt/unifi-os-server.bin \
  --cloud-init yes || exit 1

rm -f "$FIRSTBOOT_SCRIPT" "unifi-os-server.bin"
msg_ok "Disk image customized (UniFi OS ${UOS_VERSION} staged for first-boot install)"

vm_claim_vmid
msg_info "Creating UniFi OS VM"
qm create "$VMID" -agent 1${MACHINE} -tablet 0 -bios ovmf \
  ${CPU_TYPE} -cores "$CORE_COUNT" -memory "$RAM_SIZE" \
  -name "$HN" -tags community-script \
  -net0 virtio,bridge="$BRG",macaddr="$MAC""$VLAN""$MTU" \
  -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
vm_mark_created
vm_import_disk "$VMID" "$FILE" "$STORAGE" "$DISK_IMPORT_FORMAT"

qm set "$VMID" \
  -efidisk0 "${STORAGE}:0,efitype=4m" \
  -scsi0 "${VM_IMPORTED_DISK},${DISK_CACHE}size=${DISK_SIZE}" \
  -boot order=scsi0 -serial0 socket >/dev/null
vm_resize_disk
qm set "$VMID" --agent enabled=1 >/dev/null

vm_provision "$VMID"
# Core currently suppresses SSH-key write errors; keep them fatal for this VM.
if [[ -n "${CLOUDINIT_SSH_KEYS:-}" ]]; then
  qm set "$VMID" --sshkeys "$CLOUDINIT_SSH_KEYS" >/dev/null
fi

set_description

msg_ok "Created a UniFi OS VM ${CL}${BL}(${HN})"

VM_IP=""
UNIFI_READY=""
FIRSTBOOT_DONE=""
if [ "$START_VM" == "yes" ]; then
  vm_start_vm "UniFi OS VM"
  vm_wait_for_ip 360 || true

  if [[ -n "${VM_FIRSTBOOT_MARKER:-}" ]] && vm_guest_exec "$VMID" 10 test -f "$VM_FIRSTBOOT_MARKER" >/dev/null; then
    FIRSTBOOT_DONE="yes"
  else
    msg_warn "UniFi OS first-boot installation has not completed yet"
  fi

  if [[ -n "${VM_IP:-}" ]] && vm_wait_http "https://${VM_IP}:11443" 300 --insecure; then
    UNIFI_READY="yes"
    msg_ok "UniFi OS is up at https://${VM_IP}:11443"
  elif [[ -n "${VM_IP:-}" ]]; then
    msg_warn "UniFi OS is not ready; first-boot installation may still be running or may have failed"
  fi
else
  msg_info "Start VM ${VMID} to run the UniFi OS first-boot installation"
fi

vm_print_summary \
  "Operating System=${OS_DISPLAY}" \
  "UniFi OS Version=${UOS_VERSION}" \
  "Web Interface=https://${VM_IP:-<VM-IP>}:11443" \
  "Console Login=${CLOUDINIT_USER:-root}"

if [[ "$UNIFI_READY" == "yes" ]]; then
  vm_next_steps \
    "Open https://${VM_IP}:11443 and complete UniFi OS setup."
  FINISH_MESSAGE="UniFi OS Server VM is ready."
else
  vm_next_steps \
    "Wait for first-boot installation to complete in the VM: journalctl -u unifi-os-firstboot.service" \
    "Follow progress in /var/log/unifi-os-install.log inside the VM." \
    "Open https://${VM_IP:-<VM-IP>}:11443 after the installer finishes."
  if [[ "$FIRSTBOOT_DONE" == "yes" ]]; then
    FINISH_MESSAGE="VM provisioning completed; UniFi OS is installed, but web readiness was not confirmed yet."
  else
    FINISH_MESSAGE="VM provisioning completed; UniFi OS installation continues in the VM on first boot."
  fi
fi
vm_finish "$FINISH_MESSAGE"
