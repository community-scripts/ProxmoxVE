#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# ==============================================================================
# Olares VM - Creates a Personal Cloud OS Virtual Machine
# ==============================================================================
# Olares is an open-source personal cloud operating system for self-hosting
# AI models, applications, and data with enterprise-grade security.
# Requirements: 4+ CPU cores, 8+ GB RAM, 150+ GB SSD (x86-64 only)
# ==============================================================================

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/vm-core.func) 2>/dev/null
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/cloud-init.func) 2>/dev/null || true
load_functions

# ==============================================================================
# SCRIPT VARIABLES
# ==============================================================================
APP="Olares"
APP_TYPE="vm"
NSAPP="olares-vm"
var_os="ubuntu"
var_version="24.04"

GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
DISK_SIZE="160G"
USE_CLOUD_INIT="yes"
OS_TYPE="ubuntu"
OS_VERSION="24.04"
OS_CODENAME="noble"
OS_DISPLAY="Ubuntu 24.04 LTS"
THIN="discard=on,ssd=1,"

# ==============================================================================
# ERROR HANDLING & CLEANUP
# ==============================================================================
set -e
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM
trap 'post_update_to_api "failed" "129"; exit 129' SIGHUP

function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  post_update_to_api "failed" "${exit_code}"
  echo -e "\n$error_message\n"
  cleanup_vmid
}

# ==============================================================================
# OS SELECTION FUNCTIONS
# ==============================================================================
function select_os() {
  if OS_CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SELECT OS" --radiolist \
    "Choose Operating System for Olares VM\n\nOlares officially supports Ubuntu 24.04+ and Debian 12+" 14 68 4 \
    "ubuntu2404" "Ubuntu 24.04 LTS (Noble) - Recommended" ON \
    "ubuntu2204" "Ubuntu 22.04 LTS (Jammy)" OFF \
    "debian12" "Debian 12 (Bookworm)" OFF \
    "debian13" "Debian 13 (Trixie)" OFF \
    3>&1 1>&2 2>&3); then
    case $OS_CHOICE in
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
    debian12)
      OS_TYPE="debian"
      OS_VERSION="12"
      OS_CODENAME="bookworm"
      OS_DISPLAY="Debian 12 (Bookworm)"
      ;;
    debian13)
      OS_TYPE="debian"
      OS_VERSION="13"
      OS_CODENAME="trixie"
      OS_DISPLAY="Debian 13 (Trixie)"
      ;;
    esac
    echo -e "${OS}${BOLD}${DGN}Operating System: ${BGN}${OS_DISPLAY}${CL}"
  else
    exit_script
  fi
}

function get_image_url() {
  local arch=$(dpkg --print-architecture)
  case $OS_TYPE in
  ubuntu)
    echo "https://cloud-images.ubuntu.com/${OS_CODENAME}/current/${OS_CODENAME}-server-cloudimg-${arch}.img"
    ;;
  debian)
    if [ "$USE_CLOUD_INIT" = "yes" ]; then
      echo "https://cloud.debian.org/images/cloud/${OS_CODENAME}/latest/debian-${OS_VERSION}-generic-${arch}.qcow2"
    else
      echo "https://cloud.debian.org/images/cloud/${OS_CODENAME}/latest/debian-${OS_VERSION}-nocloud-${arch}.qcow2"
    fi
    ;;
  esac
}

# ==============================================================================
# SETTINGS FUNCTIONS
# ==============================================================================
function default_settings() {
  select_os

  VMID=$(get_valid_nextid)
  FORMAT=""
  MACHINE=" -machine q35"
  DISK_CACHE=""
  DISK_SIZE="160G"
  HN="olares"
  CPU_TYPE=" -cpu host"
  CORE_COUNT="4"
  RAM_SIZE="8192"
  BRG="vmbr0"
  MAC="$GEN_MAC"
  VLAN=""
  MTU=""
  START_VM="yes"
  METHOD="default"

  echo -e "${CONTAINERID}${BOLD}${DGN}Virtual Machine ID: ${BGN}${VMID}${CL}"
  echo -e "${CONTAINERTYPE}${BOLD}${DGN}Machine Type: ${BGN}Q35 (Modern)${CL}"
  echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}${DISK_SIZE}${CL}"
  echo -e "${DISKSIZE}${BOLD}${DGN}Disk Cache: ${BGN}None${CL}"
  echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}${HN}${CL}"
  echo -e "${OS}${BOLD}${DGN}CPU Model: ${BGN}Host${CL}"
  echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}${CORE_COUNT}${CL}"
  echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}${RAM_SIZE}${CL}"
  echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}${BRG}${CL}"
  echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}${MAC}${CL}"
  echo -e "${VLANTAG}${BOLD}${DGN}VLAN: ${BGN}Default${CL}"
  echo -e "${DEFAULT}${BOLD}${DGN}Interface MTU Size: ${BGN}Default${CL}"
  echo -e "${GATEWAY}${BOLD}${DGN}Start VM when completed: ${BGN}yes${CL}"
  echo -e "${CREATING}${BOLD}${DGN}Creating an Olares VM using the above settings${CL}"
}

function advanced_settings() {
  select_os

  # SSH Key selection for Cloud-Init VMs
  if [ "$USE_CLOUD_INIT" = "yes" ]; then
    configure_cloudinit_ssh_keys || true
  fi

  METHOD="advanced"
  [ -z "${VMID:-}" ] && VMID=$(get_valid_nextid)

  # VM ID
  while true; do
    if VMID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Virtual Machine ID" 8 58 "$VMID" --title "VIRTUAL MACHINE ID" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
      if [ -z "$VMID" ]; then
        VMID=$(get_valid_nextid)
      fi
      if pct status "$VMID" &>/dev/null || qm status "$VMID" &>/dev/null; then
        echo -e "${CROSS}${RD} ID $VMID is already in use${CL}"
        sleep 2
        continue
      fi
      echo -e "${CONTAINERID}${BOLD}${DGN}Virtual Machine ID: ${BGN}$VMID${CL}"
      break
    else
      exit_script
    fi
  done

  # Machine Type
  if MACH=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "MACHINE TYPE" --radiolist --cancel-button Exit-Script "Choose Type" 10 58 2 \
    "q35" "Q35 (Modern, PCIe)" ON \
    "i440fx" "i440fx (Legacy, PCI)" OFF \
    3>&1 1>&2 2>&3); then
    if [ "$MACH" = q35 ]; then
      echo -e "${CONTAINERTYPE}${BOLD}${DGN}Machine Type: ${BGN}Q35 (Modern)${CL}"
      FORMAT=""
      MACHINE=" -machine q35"
    else
      echo -e "${CONTAINERTYPE}${BOLD}${DGN}Machine Type: ${BGN}i440fx (Legacy)${CL}"
      FORMAT=",efitype=4m"
      MACHINE=""
    fi
  else
    exit_script
  fi

  # Disk Size
  if DISK_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Disk Size in GiB (minimum 150GB for Olares)" 8 58 "$DISK_SIZE" --title "DISK SIZE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    DISK_SIZE=$(echo "$DISK_SIZE" | tr -d ' ')
    if [[ "$DISK_SIZE" =~ ^[0-9]+$ ]]; then
      DISK_SIZE="${DISK_SIZE}G"
      echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}$DISK_SIZE${CL}"
    elif [[ "$DISK_SIZE" =~ ^[0-9]+G$ ]]; then
      echo -e "${DISKSIZE}${BOLD}${DGN}Disk Size: ${BGN}$DISK_SIZE${CL}"
    else
      echo -e "${DISKSIZE}${BOLD}${RD}Invalid Disk Size. Please use a number (e.g., 160 or 160G).${CL}"
      exit_script
    fi
  else
    exit_script
  fi

  # Disk Cache
  if DISK_CACHE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "DISK CACHE" --radiolist "Choose" --cancel-button Exit-Script 10 58 2 \
    "0" "None (Default)" ON \
    "1" "Write Through" OFF \
    3>&1 1>&2 2>&3); then
    if [ "$DISK_CACHE" = "1" ]; then
      echo -e "${DISKSIZE}${BOLD}${DGN}Disk Cache: ${BGN}Write Through${CL}"
      DISK_CACHE="cache=writethrough,"
    else
      echo -e "${DISKSIZE}${BOLD}${DGN}Disk Cache: ${BGN}None${CL}"
      DISK_CACHE=""
    fi
  else
    exit_script
  fi

  # Hostname
  if VM_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Hostname" 8 58 olares --title "HOSTNAME" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$VM_NAME" ]; then
      HN="olares"
    else
      HN=$(echo "${VM_NAME,,}" | tr -d ' ')
    fi
    echo -e "${HOSTNAME}${BOLD}${DGN}Hostname: ${BGN}$HN${CL}"
  else
    exit_script
  fi

  # CPU Model
  if CPU_TYPE1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CPU MODEL" --radiolist "Choose" --cancel-button Exit-Script 10 58 2 \
    "1" "Host (Recommended for Olares)" ON \
    "0" "KVM64" OFF \
    3>&1 1>&2 2>&3); then
    if [ "$CPU_TYPE1" = "1" ]; then
      echo -e "${OS}${BOLD}${DGN}CPU Model: ${BGN}Host${CL}"
      CPU_TYPE=" -cpu host"
    else
      echo -e "${OS}${BOLD}${DGN}CPU Model: ${BGN}KVM64${CL}"
      CPU_TYPE=""
    fi
  else
    exit_script
  fi

  # CPU Cores
  if CORE_COUNT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores (minimum 4 for Olares)" 8 58 4 --title "CORE COUNT" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$CORE_COUNT" ]; then
      CORE_COUNT="4"
    fi
    echo -e "${CPUCORE}${BOLD}${DGN}CPU Cores: ${BGN}$CORE_COUNT${CL}"
  else
    exit_script
  fi

  # RAM Size
  if RAM_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in MiB (minimum 8192 for Olares)" 8 58 8192 --title "RAM" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$RAM_SIZE" ]; then
      RAM_SIZE="8192"
    fi
    echo -e "${RAMSIZE}${BOLD}${DGN}RAM Size: ${BGN}$RAM_SIZE${CL}"
  else
    exit_script
  fi

  # Bridge
  if BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Bridge" 8 58 vmbr0 --title "BRIDGE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$BRG" ]; then
      BRG="vmbr0"
    fi
    echo -e "${BRIDGE}${BOLD}${DGN}Bridge: ${BGN}$BRG${CL}"
  else
    exit_script
  fi

  # MAC Address
  if MAC1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a MAC Address" 8 58 "$GEN_MAC" --title "MAC ADDRESS" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$MAC1" ]; then
      MAC="$GEN_MAC"
    else
      MAC="$MAC1"
    fi
    echo -e "${MACADDRESS}${BOLD}${DGN}MAC Address: ${BGN}$MAC${CL}"
  else
    exit_script
  fi

  # VLAN
  if VLAN1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Vlan (leave blank for default)" 8 58 --title "VLAN" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$VLAN1" ]; then
      VLAN1="Default"
      VLAN=""
    else
      VLAN=",tag=$VLAN1"
    fi
    echo -e "${VLANTAG}${BOLD}${DGN}VLAN: ${BGN}$VLAN1${CL}"
  else
    exit_script
  fi

  # MTU
  if MTU1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Interface MTU Size (leave blank for default)" 8 58 --title "MTU SIZE" --cancel-button Exit-Script 3>&1 1>&2 2>&3); then
    if [ -z "$MTU1" ]; then
      MTU1="Default"
      MTU=""
    else
      MTU=",mtu=$MTU1"
    fi
    echo -e "${DEFAULT}${BOLD}${DGN}Interface MTU Size: ${BGN}$MTU1${CL}"
  else
    exit_script
  fi

  # Start VM
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "START VIRTUAL MACHINE" --yesno "Start VM when completed?" 10 58); then
    echo -e "${GATEWAY}${BOLD}${DGN}Start VM when completed: ${BGN}yes${CL}"
    START_VM="yes"
  else
    echo -e "${GATEWAY}${BOLD}${DGN}Start VM when completed: ${BGN}no${CL}"
    START_VM="no"
  fi

  # Confirm
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "ADVANCED SETTINGS COMPLETE" --yesno "Ready to create an Olares VM?" --no-button Do-Over 10 58); then
    echo -e "${CREATING}${BOLD}${DGN}Creating an Olares VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

function start_script() {
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "SETTINGS" --yesno "Use Default Settings?" --no-button Advanced 10 58); then
    header_info
    echo -e "${DEFAULT}${BOLD}${BL}Using Default Settings${CL}"
    default_settings
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

check_root
arch_check
pve_check

if whiptail --backtitle "Proxmox VE Helper Scripts" --title "Olares VM" --yesno "This will create a New Olares VM.\n\nOlares is a personal cloud OS for self-hosting:\n• Local AI models (LLMs, image generation)\n• File sync and media streaming\n• Enterprise-grade security\n\nRequirements:\n• 4+ CPU cores (x86-64 only)\n• 8+ GB RAM\n• 150+ GB SSD storage\n\nProceed?" 18 68; then
  :
else
  header_info && echo -e "${CROSS}${RD}User exited script${CL}\n" && exit
fi

start_script
post_to_api_vm

# ==============================================================================
# STORAGE SELECTION
# ==============================================================================
msg_info "Validating Storage"
while read -r line; do
  TAG=$(echo "$line" | awk '{print $1}')
  TYPE=$(echo "$line" | awk '{printf "%-10s", $2}')
  FREE=$(echo "$line" | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
  ITEM="  Type: $TYPE Free: $FREE "
  OFFSET=2
  if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
    MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
  fi
  STORAGE_MENU+=("$TAG" "$ITEM" "OFF")
done < <(pvesm status -content images | awk 'NR>1')

VALID=$(pvesm status -content images | awk 'NR>1')
if [ -z "$VALID" ]; then
  msg_error "Unable to detect a valid storage location."
  exit
elif [ $((${#STORAGE_MENU[@]} / 3)) -eq 1 ]; then
  STORAGE=${STORAGE_MENU[0]}
else
  if [ -n "$SPINNER_PID" ] && ps -p "$SPINNER_PID" >/dev/null; then kill "$SPINNER_PID" >/dev/null; fi
  printf "\e[?25h"
  while [ -z "${STORAGE:+x}" ]; do
    STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
      "Which storage pool would you like to use for ${HN}?\nTo make a selection, use the Spacebar.\n" \
      16 $(($MSG_MAX_LENGTH + 23)) 6 \
      "${STORAGE_MENU[@]}" 3>&1 1>&2 2>&3)
  done
fi
msg_ok "Using ${CL}${BL}$STORAGE${CL} ${GN}for Storage Location."
msg_ok "Virtual Machine ID is ${CL}${BL}$VMID${CL}."

# ==============================================================================
# PREREQUISITES
# ==============================================================================
if ! command -v virt-customize &>/dev/null; then
  msg_info "Installing libguestfs-tools"
  apt-get -qq update >/dev/null
  apt-get -qq install libguestfs-tools lsb-release -y >/dev/null
  apt-get -qq install dhcpcd-base -y >/dev/null 2>&1 || true
  msg_ok "Installed libguestfs-tools"
fi

# ==============================================================================
# IMAGE DOWNLOAD
# ==============================================================================
msg_info "Retrieving the URL for the ${OS_DISPLAY} Cloud Image"
URL=$(get_image_url)
CACHE_DIR="/var/lib/vz/template/cache"
CACHE_FILE="$CACHE_DIR/$(basename "$URL")"
mkdir -p "$CACHE_DIR"
msg_ok "${CL}${BL}${URL}${CL}"

if [[ ! -s "$CACHE_FILE" ]]; then
  curl -f#SL -o "$CACHE_FILE" "$URL"
  echo -en "\e[1A\e[0K"
  msg_ok "Downloaded ${CL}${BL}$(basename "$CACHE_FILE")${CL}"
else
  msg_ok "Using cached image ${CL}${BL}$(basename "$CACHE_FILE")${CL}"
fi

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
# IMAGE CUSTOMIZATION WITH OLARES INSTALLER
# ==============================================================================
msg_info "Preparing ${OS_DISPLAY} image with Olares installer"

WORK_FILE=$(mktemp --suffix=.img)
cp "$CACHE_FILE" "$WORK_FILE"

export LIBGUESTFS_BACKEND_SETTINGS=dns=8.8.8.8,1.1.1.1

OLARES_INSTALLED="no"

# Install qemu-guest-agent and prepare system
msg_info "Installing base packages in image"
if virt-customize -a "$WORK_FILE" --install qemu-guest-agent,curl,ca-certificates >/dev/null 2>&1; then
  msg_ok "Installed base packages"

  msg_info "Configuring system for Olares"
  # Set hostname
  virt-customize -q -a "$WORK_FILE" --hostname "${HN}" >/dev/null 2>&1 || true
  
  # Prepare machine-id for unique instance
  virt-customize -q -a "$WORK_FILE" --run-command "truncate -s 0 /etc/machine-id" >/dev/null 2>&1 || true
  virt-customize -q -a "$WORK_FILE" --run-command "rm -f /var/lib/dbus/machine-id" >/dev/null 2>&1 || true

  # Configure SSH for Cloud-Init
  if [ "$USE_CLOUD_INIT" = "yes" ]; then
    virt-customize -q -a "$WORK_FILE" --run-command "sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config" >/dev/null 2>&1 || true
    virt-customize -q -a "$WORK_FILE" --run-command "sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config" >/dev/null 2>&1 || true
  fi

  # Create Olares installation script
  msg_info "Creating Olares installation script"
  if virt-customize -q -a "$WORK_FILE" --run-command 'cat > /root/install-olares.sh << "OLARESSCRIPT"
#!/bin/bash
exec > /var/log/olares-install.log 2>&1
echo "[$(date)] Starting Olares installation"

# Wait for network
for i in {1..30}; do
  ping -c 1 8.8.8.8 >/dev/null 2>&1 && break
  sleep 2
done

# Check if already installed
if [ -f /root/.olares-installed ]; then
  echo "[$(date)] Olares already installed, skipping"
  exit 0
fi

# Install Olares using official installer
echo "[$(date)] Downloading and running Olares installer"
curl -fsSL https://olares.sh | bash -

# Mark installation complete
touch /root/.olares-installed
echo "[$(date)] Olares installation completed"
echo "[$(date)] Please activate Olares using the LarePass mobile app"
OLARESSCRIPT
chmod +x /root/install-olares.sh' >/dev/null 2>&1; then

    # Create systemd service for first-boot installation
    virt-customize -q -a "$WORK_FILE" --run-command 'cat > /etc/systemd/system/olares-install.service << "OLARESSERVICE"
[Unit]
Description=Install Olares on First Boot
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/root/.olares-installed

[Service]
Type=oneshot
ExecStart=/root/install-olares.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
OLARESSERVICE
systemctl enable olares-install.service' >/dev/null 2>&1 || true

    OLARES_INSTALLED="yes"
    msg_ok "Created Olares installation script"
  else
    msg_warn "virt-customize failed for this image. Olares must be installed manually after first boot:"
    msg_warn "  curl -fsSL https://olares.sh | bash -"
  fi
else
  msg_ok "Packages will be installed on first boot"
fi

# Resize disk to target size
msg_info "Resizing disk image to ${DISK_SIZE}"
qemu-img resize "$WORK_FILE" "${DISK_SIZE}" >/dev/null 2>&1
msg_ok "Resized disk image"

# ==============================================================================
# VM CREATION
# ==============================================================================
msg_info "Creating Olares VM shell"

qm create "$VMID" -agent 1"${MACHINE}" -tablet 0 -localtime 1 -bios ovmf"${CPU_TYPE}" -cores "$CORE_COUNT" -memory "$RAM_SIZE" \
  -name "$HN" -tags community-script -net0 virtio,bridge="$BRG",macaddr="$MAC""$VLAN""$MTU" -onboot 1 -ostype l26 -scsihw virtio-scsi-pci >/dev/null

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

IMPORT_OUT="$("${IMPORT_CMD[@]}" "$VMID" "$WORK_FILE" "$STORAGE" "${DISK_IMPORT:-}" 2>&1 || true)"
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

qm set "$VMID" --agent enabled=1 >/dev/null

msg_ok "Attached EFI and root disk"

# Set VM description
set_description

# Cloud-Init configuration
if [ "$USE_CLOUD_INIT" = "yes" ]; then
  msg_info "Configuring Cloud-Init"
  setup_cloud_init "$VMID" "$STORAGE" "$HN" "yes"
  msg_ok "Cloud-Init configured"
fi

# Start VM
if [ "$START_VM" == "yes" ]; then
  msg_info "Starting Olares VM"
  qm start "$VMID" >/dev/null 2>&1
  msg_ok "Started Olares VM"
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

echo -e "\n${INFO}${BOLD}${GN}Olares VM Configuration Summary:${CL}"
echo -e "${TAB}${DGN}VM ID: ${BGN}${VMID}${CL}"
echo -e "${TAB}${DGN}Hostname: ${BGN}${HN}${CL}"
echo -e "${TAB}${DGN}OS: ${BGN}${OS_DISPLAY}${CL}"
[ -n "$VM_IP" ] && echo -e "${TAB}${DGN}IP Address: ${BGN}${VM_IP}${CL}"

if [ "$OLARES_INSTALLED" = "yes" ]; then
  echo -e "${TAB}${DGN}Olares: ${BGN}Installing on first boot${CL}"
  echo -e "${TAB}${YW}⚠️  Wait 5-10 minutes for installation to complete${CL}"
  echo -e "${TAB}${YW}⚠️  Check progress: ${BL}cat /var/log/olares-install.log${CL}"
else
  echo -e "${TAB}${DGN}Olares: ${BGN}Manual installation required${CL}"
  echo -e "${TAB}${YW}⚠️  Run after first boot: ${BL}curl -fsSL https://olares.sh | bash -${CL}"
fi

echo -e "\n${INFO}${BOLD}${GN}Post-Installation Steps:${CL}"
echo -e "${TAB}1. Wait for Olares installation to complete (5-10 minutes)"
echo -e "${TAB}2. Install LarePass mobile app"
echo -e "${TAB}3. Scan QR code or visit Wizard URL to activate"
echo -e "${TAB}4. Access Olares at: ${BL}https://desktop.{your-id}.olares.com${CL}"
echo -e "${TAB}5. Documentation: ${BL}https://docs.olares.com/${CL}"

if [ "$USE_CLOUD_INIT" = "yes" ]; then
  display_cloud_init_info "$VMID" "$HN" 2>/dev/null || true
fi

post_update_to_api "done" "none"
msg_ok "Completed successfully!\n"
