#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: thost96 (thost96) | michelroegl-brunner | MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE

# ==============================================================================
# Docker VM - Creates a Docker-ready Virtual Machine
# ==============================================================================

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

# ==============================================================================
# SCRIPT VARIABLES
# ==============================================================================
APP="Docker"
APP_TYPE="vm"
NSAPP="docker-vm"
var_os="debian"
var_version="13"
ARCH=$(dpkg --print-architecture)

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
DISK_SIZE="10G"
USE_CLOUD_INIT="no"
OS_TYPE=""
OS_VERSION=""
THIN="discard=on,ssd=1,"
var_arm64="yes"

# ==============================================================================
# ERROR HANDLING & CLEANUP
# ==============================================================================
set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

# ==============================================================================
# OS SELECTION FUNCTIONS
# ==============================================================================
function select_os() {
  if [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
    OS_CHOICE="${VM_OS_VERSION:-debian13}"
  elif ! OS_CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SELECT OS" --radiolist \
    "Choose Operating System for Docker VM" 15 68 5 \
    "debian13" "Debian 13 (Trixie) - Latest" ON \
    "debian12" "Debian 12 (Bookworm) - Stable" OFF \
    "ubuntu2604" "Ubuntu 26.04 LTS (Resolute)" OFF \
    "ubuntu2404" "Ubuntu 24.04 LTS (Noble)" OFF \
    "ubuntu2204" "Ubuntu 22.04 LTS (Jammy)" OFF \
    3>&1 1>&2 2>&3); then
    exit_script
  fi

  case $OS_CHOICE in
  debian13)
    OS_TYPE="debian"
    OS_VERSION="13"
    OS_CODENAME="trixie"
    OS_DISPLAY="Debian 13 (Trixie)"
    ;;
  debian12)
    OS_TYPE="debian"
    OS_VERSION="12"
    OS_CODENAME="bookworm"
    OS_DISPLAY="Debian 12 (Bookworm)"
    ;;
  ubuntu2604)
    OS_TYPE="ubuntu"
    OS_VERSION="26.04"
    OS_CODENAME="resolute"
    OS_DISPLAY="Ubuntu 26.04 LTS"
    ;;
  ubuntu2404)
    OS_TYPE="ubuntu"
    OS_VERSION="24.04"
    OS_CODENAME="noble"
    OS_DISPLAY="Ubuntu 24.04 LTS"
    ;;
  ubuntu2204)
    OS_TYPE="ubuntu"
    OS_VERSION="22.04"
    OS_CODENAME="jammy"
    OS_DISPLAY="Ubuntu 22.04 LTS"
    ;;
  *)
    msg_error "Unsupported OS '${OS_CHOICE}' (expected debian13, debian12, ubuntu2604, ubuntu2404 or ubuntu2204)"
    exit 1
    ;;
  esac
  echo -e "${OS}${BOLD}${DGN}Operating System: ${BGN}${OS_DISPLAY}${CL}"
}

function select_cloud_init() {
  vm_prompt_cloud_init "root"

  # Ubuntu ships only cloud images; without cloud-init there is no way in.
  if [ "$OS_TYPE" = "ubuntu" ] && [ "$USE_CLOUD_INIT" != "yes" ]; then
    USE_CLOUD_INIT="yes"
    export CLOUDINIT_ENABLE="yes"
    msg_warn "Ubuntu requires Cloud-Init - enabling it anyway"
  fi
}

function get_image_url() {
  local arch=$(dpkg --print-architecture)
  case $OS_TYPE in
  debian)
    if [ "$USE_CLOUD_INIT" = "yes" ]; then
      echo "https://cloud.debian.org/images/cloud/${OS_CODENAME}/latest/debian-${OS_VERSION}-generic-${arch}.qcow2"
    else
      echo "https://cloud.debian.org/images/cloud/${OS_CODENAME}/latest/debian-${OS_VERSION}-nocloud-${arch}.qcow2"
    fi
    ;;
  ubuntu)
    echo "https://cloud-images.ubuntu.com/${OS_CODENAME}/current/${OS_CODENAME}-server-cloudimg-${arch}.img"
    ;;
  esac
}

# ==============================================================================
# SETTINGS FUNCTIONS
# ==============================================================================
function default_settings() {
  vm_apply_machine_type "q35"
  select_os
  select_cloud_init

  VMID=$(get_valid_nextid)
  if [ "$ARCH" = "arm64" ]; then
    CPU_TYPE=""
  else
    CPU_TYPE=" -cpu host"
  fi
  DISK_CACHE=""
  DISK_SIZE="10G"
  HN="docker"
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
  select_os
  select_cloud_init
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "10G"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "docker"
  vm_prompt_cpu_model "host"
  vm_prompt_cpu_cores "2"
  vm_prompt_ram "4096"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a Docker VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a Docker VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}


# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
header_info

vm_preflight

vm_start_script "Use Default Settings?" 10 58
post_to_api_vm

# ==============================================================================
# STORAGE SELECTION
# ==============================================================================
vm_select_storage "$HN"

# ==============================================================================
# PREREQUISITES
# ==============================================================================
vm_ensure_virt_customize
$STD apt-get -qq install lsb-release dhcpcd-base -y 2>/dev/null || true

# ==============================================================================
# IMAGE DOWNLOAD
# ==============================================================================
msg_info "Retrieving the URL for the ${OS_DISPLAY} Qcow2 Disk Image"
URL=$(get_image_url)
CACHE_DIR="/var/lib/vz/template/cache"
CACHE_FILE="$CACHE_DIR/$(basename "$URL")"
mkdir -p "$CACHE_DIR"
msg_ok "${CL}${BL}${URL}${CL}"

MIN_IMAGE_BYTES=$((100 * 1024 * 1024))
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes "$MIN_IMAGE_BYTES" || exit 115

# ==============================================================================
# STORAGE TYPE DETECTION
# ==============================================================================
STORAGE_TYPE=$(pvesm status -storage "$STORAGE" | awk 'NR>1 {print $2}')
case $STORAGE_TYPE in
nfs | dir)
  DISK_EXT=".qcow2"
  DISK_REF="$VMID/"
  DISK_IMPORT="--format qcow2"
  THIN=""
  ;;
btrfs)
  DISK_EXT=".raw"
  DISK_REF="$VMID/"
  DISK_IMPORT="--format raw"
  FORMAT=",efitype=4m"
  THIN=""
  ;;
*)
  DISK_EXT=""
  DISK_REF=""
  DISK_IMPORT="--format raw"
  ;;
esac

# ==============================================================================
# IMAGE CUSTOMIZATION WITH DOCKER
# ==============================================================================
msg_info "Preparing ${OS_DISPLAY} image with Docker"

WORK_FILE=$(mktemp --suffix=.qcow2)
cp "$CACHE_FILE" "$WORK_FILE"

# qm resize only grows the block device. Without cloud-init nothing grows the
# guest partition, so expand the working copy offline first.
if [ "${USE_CLOUD_INIT:-no}" != "yes" ]; then
  msg_info "Expanding the root filesystem to ${DISK_SIZE}"
  vm_expand_image "$WORK_FILE" "$DISK_SIZE" || true
fi

export LIBGUESTFS_BACKEND_SETTINGS=dns=8.8.8.8,1.1.1.1

DOCKER_PREINSTALLED="no"

# Install qemu-guest-agent and Docker during image customization
msg_info "Installing base packages in image"
if virt-customize -a "$WORK_FILE" --install qemu-guest-agent,curl,ca-certificates >/dev/null 2>&1; then
  msg_ok "Installed base packages"

  msg_info "Installing Docker (this may take 2-5 minutes)"
  if virt-customize -q -a "$WORK_FILE" --run-command "curl -fsSL https://get.docker.com | sh" >/dev/null 2>&1 &&
    virt-customize -q -a "$WORK_FILE" --run-command "systemctl enable docker" >/dev/null 2>&1; then
    msg_ok "Installed Docker"

    msg_info "Configuring Docker daemon"
    # Optimize Docker daemon configuration
    virt-customize -q -a "$WORK_FILE" --run-command "mkdir -p /etc/docker" >/dev/null 2>&1
    virt-customize -q -a "$WORK_FILE" --run-command 'cat > /etc/docker/daemon.json << EOF
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF' >/dev/null 2>&1
    DOCKER_PREINSTALLED="yes"
    msg_ok "Configured Docker daemon"
  else
    msg_ok "Docker will be installed on first boot"
  fi
else
  msg_ok "Packages will be installed on first boot"
fi

msg_info "Finalizing image (hostname, SSH config)"
# Set hostname and prepare for unique machine-id
vm_prepare_cloud_image "$WORK_FILE" "$HN" || true

# Configure SSH for Cloud-Init
if [ "$USE_CLOUD_INIT" = "yes" ]; then
  virt-customize -q -a "$WORK_FILE" --run-command "sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config" >/dev/null 2>&1 || true
  virt-customize -q -a "$WORK_FILE" --run-command "sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config" >/dev/null 2>&1 || true
else
  # Configure auto-login for nocloud images (no Cloud-Init)
  virt-customize -q -a "$WORK_FILE" --run-command "mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d" >/dev/null 2>&1 || true
  virt-customize -q -a "$WORK_FILE" --run-command 'cat > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF' >/dev/null 2>&1 || true
  virt-customize -q -a "$WORK_FILE" --run-command "mkdir -p /etc/systemd/system/getty@tty1.service.d" >/dev/null 2>&1 || true
  virt-customize -q -a "$WORK_FILE" --run-command 'cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF' >/dev/null 2>&1 || true
fi
msg_ok "Finalized image"

# Create first-boot Docker install script (fallback if virt-customize failed)
if [ "$DOCKER_PREINSTALLED" = "no" ]; then
  if virt-customize -q -a "$WORK_FILE" --run-command 'cat > /root/install-docker.sh << "DOCKERSCRIPT"
#!/bin/bash
exec > /var/log/install-docker.log 2>&1
echo "[$(date)] Starting Docker installation"

for i in {1..30}; do
  ping -c 1 8.8.8.8 >/dev/null 2>&1 && break
  sleep 2
done

apt-get update
apt-get install -y qemu-guest-agent curl ca-certificates
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

mkdir -p /etc/docker
cat > /etc/docker/daemon.json << DAEMON
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
DAEMON
systemctl restart docker

touch /root/.docker-installed
echo "[$(date)] Docker installation completed"
DOCKERSCRIPT
chmod +x /root/install-docker.sh' >/dev/null 2>&1; then

    virt-customize -q -a "$WORK_FILE" --run-command 'cat > /etc/systemd/system/install-docker.service << "DOCKERSERVICE"
[Unit]
Description=Install Docker on First Boot
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/root/.docker-installed

[Service]
Type=oneshot
ExecStart=/root/install-docker.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
DOCKERSERVICE
systemctl enable install-docker.service' >/dev/null 2>&1 || true
  else
    msg_warn "virt-customize failed for this image. Docker must be installed manually after first boot:"
    msg_warn "  curl -fsSL https://get.docker.com | sh"
  fi
fi

# Resize disk to target size
msg_info "Resizing disk image to ${DISK_SIZE}"
qemu-img resize "$WORK_FILE" "${DISK_SIZE}" >/dev/null 2>&1
msg_ok "Resized disk image"

# ==============================================================================
# VM CREATION
# ==============================================================================
msg_info "Creating Docker VM shell"

qm create $VMID -agent 1${MACHINE} -tablet 0 -localtime 1 -bios ovmf${CPU_TYPE} -cores $CORE_COUNT -memory $RAM_SIZE \
  -name $HN -tags community-script -net0 virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU -onboot 1 -ostype l26 -scsihw virtio-scsi-pci >/dev/null

msg_ok "Created VM shell"

# ==============================================================================
# DISK IMPORT
# ==============================================================================
msg_info "Importing disk into storage ($STORAGE)"

if qm disk import --help >/dev/null 2>&1; then
  IMPORT_CMD=(qm disk import)
else
  IMPORT_CMD=(qm importdisk)
fi

IMPORT_OUT="$("${IMPORT_CMD[@]}" "$VMID" "$WORK_FILE" "$STORAGE" ${DISK_IMPORT:-} 2>&1 || true)"
DISK_REF_IMPORTED="$(printf '%s\n' "$IMPORT_OUT" | sed -n "s/.*successfully imported disk '\([^']\+\)'.*/\1/p" | tr -d "\r\"'")"
[[ -z "$DISK_REF_IMPORTED" ]] && DISK_REF_IMPORTED="$(pvesm list "$STORAGE" | awk -v id="$VMID" '$5 ~ ("vm-"id"-disk-") {print $1":"$5}' | sort | tail -n1)"
[[ -z "$DISK_REF_IMPORTED" ]] && {
  msg_error "Unable to determine imported disk reference."
  echo "$IMPORT_OUT"
  exit 226
}

msg_ok "Imported disk (${CL}${BL}${DISK_REF_IMPORTED}${CL})"

# Clean up work file
rm -f "$WORK_FILE"

# ==============================================================================
# VM CONFIGURATION
# ==============================================================================
msg_info "Attaching EFI and root disk"

qm set "$VMID" \
  --efidisk0 "${STORAGE}:0,efitype=4m" \
  --scsi0 "${DISK_REF_IMPORTED},${DISK_CACHE}${THIN%,}" \
  --boot order=scsi0 \
  --serial0 socket >/dev/null

qm set $VMID --agent enabled=1 >/dev/null

msg_ok "Attached EFI and root disk"

# Set VM description
set_description

# Cloud-Init configuration
msg_info "Configuring Cloud-Init"
if vm_provision "$VMID"; then
  msg_ok "Cloud-Init configured"
else
  msg_warn "VM created, but not provisioned"
fi

# Start VM
if [ "$START_VM" == "yes" ]; then
  msg_info "Starting Docker VM"
  $STD qm start $VMID
  msg_ok "Started Docker VM"
fi

# ==============================================================================
# FINAL OUTPUT
# ==============================================================================
VM_IP=""
if [ "$START_VM" == "yes" ]; then
  set +e
  for i in {1..10}; do
    VM_IP=$(qm guest cmd "$VMID" network-get-interfaces 2>/dev/null |
      jq -r '.[] | select(.name != "lo") | ."ip-addresses"[]? | select(."ip-address-type" == "ipv4") | ."ip-address"' 2>/dev/null |
      grep -v "^127\." | head -1) || true
    [ -n "$VM_IP" ] && break
    sleep 3
  done
  set -e
fi

echo -e "\n${INFO}${BOLD}${GN}Docker VM Configuration Summary:${CL}"
echo -e "${TAB}${DGN}VM ID: ${BGN}${VMID}${CL}"
echo -e "${TAB}${DGN}Hostname: ${BGN}${HN}${CL}"
echo -e "${TAB}${DGN}OS: ${BGN}${OS_DISPLAY}${CL}"
[ -n "$VM_IP" ] && echo -e "${TAB}${DGN}IP Address: ${BGN}${VM_IP}${CL}"

if [ "$DOCKER_PREINSTALLED" = "yes" ]; then
  echo -e "${TAB}${DGN}Docker: ${BGN}Pre-installed (via get.docker.com)${CL}"
else
  echo -e "${TAB}${DGN}Docker: ${BGN}Installing on first boot${CL}"
  echo -e "${TAB}${YW}⚠️  Wait 2-3 minutes for installation to complete${CL}"
  echo -e "${TAB}${YW}⚠️  Check progress: ${BL}cat /var/log/install-docker.log${CL}"
fi

if [ "$USE_CLOUD_INIT" = "yes" ]; then
  display_cloud_init_info "$VMID" "$HN" 2>/dev/null || true
fi

post_update_to_api "done" "none"
msg_ok "Completed successfully!\n"
