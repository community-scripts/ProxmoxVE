#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

set -Eeuo pipefail

function header_info() {
  clear
  cat <<"EOF"
   __________  __  __   ____             __  __                          __
  / ____/ __ \/ / / /  / __ \____ ______/ /_/ /_  _________  __  ______ _/ /_
 / / __/ /_/ / / / /  / /_/ / __ `/ ___/ __/ __ \/ ___/ __ \/ / / / __ `/ __ \
/ /_/ / ____/ /_/ /  / ____/ /_/ (__  ) /_/ / / / /  / /_/ / /_/ / /_/ / / / /
\____/_/    \____/  /_/    \__,_/____/\__/_/ /_/_/   \____/\__,_/\__, /_/ /_/
                                                                /____/
EOF
}

RD="\033[01;31m"
YW="\033[33m"
GN="\033[1;92m"
BL="\033[36m"
CL="\033[m"
BFR="\r\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
WARN="${YW}!${CL}"

msg_info() { echo -e " ${HOLD} ${YW}$1...${CL}"; }
msg_ok() { echo -e "${BFR} ${CM} ${GN}$1${CL}"; }
msg_error() { echo -e "${BFR} ${CROSS} ${RD}$1${CL}"; }
msg_warn() { echo -e " ${WARN} ${YW}$1${CL}"; }

# Telemetry
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/api/api.func") 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "gpu-passthrough" "pve"

VFIO_CONF="/etc/modprobe.d/vfio.conf"
GRUB_CONF="/etc/default/grub"
MODULES_CONF="/etc/modules"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# Check root and PVE environment
if [ "$(id -u)" -ne 0 ]; then
  header_info
  msg_error "This script must be run as root."
  exit 1
fi

if ! command -v pveversion >/dev/null 2>&1; then
  header_info
  msg_error "No Proxmox VE Detected!"
  exit 1
fi

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp "$f" "${f}${BACKUP_SUFFIX}"
    msg_ok "Backed up $f -> ${f}${BACKUP_SUFFIX}"
  fi
}

ensure_vfio_conf() {
  if [[ ! -f "$VFIO_CONF" ]]; then
    touch "$VFIO_CONF"
  fi
}

grub_add_param() {
  local param="$1"
  if grep -q "GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_CONF"; then
    if ! grep -q "$param" "$GRUB_CONF"; then
      sed -i "s/\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)/\1 ${param}/" "$GRUB_CONF"
      msg_ok "Added '$param' to GRUB cmdline"
    else
      msg_warn "'$param' already present in GRUB cmdline"
    fi
  else
    msg_error "GRUB_CMDLINE_LINUX_DEFAULT not found in $GRUB_CONF"
    return 1
  fi
}

grub_remove_param() {
  local param="$1"
  if grep -q "$param" "$GRUB_CONF"; then
    sed -i "s/ ${param}//" "$GRUB_CONF"
    msg_ok "Removed '$param' from GRUB cmdline"
  fi
}

add_module() {
  local mod="$1"
  if ! grep -qx "$mod" "$MODULES_CONF"; then
    echo "$mod" >> "$MODULES_CONF"
    msg_ok "Added module $mod to $MODULES_CONF"
  fi
}

remove_module() {
  local mod="$1"
  sed -i "/^${mod}$/d" "$MODULES_CONF"
}

add_softdep() {
  local driver="$1"
  local line="softdep ${driver} pre: vfio-pci"
  ensure_vfio_conf
  if ! grep -qxF "$line" "$VFIO_CONF"; then
    echo "$line" >> "$VFIO_CONF"
  fi
}

remove_softdep() {
  local driver="$1"
  if [[ -f "$VFIO_CONF" ]]; then
    sed -i "/^softdep ${driver} pre: vfio-pci$/d" "$VFIO_CONF"
  fi
}

check_virtualization() {
  header_info
  msg_info "Checking CPU Virtualization and IOMMU"

  local virt_type
  virt_type=$(lscpu | grep -i virtualization || true)

  local virt_status="Not enabled"
  if [[ "$virt_type" == *'VT-x'* ]]; then
    virt_status="Intel VT-x enabled"
  elif [[ "$virt_type" == *'AMD-V'* ]]; then
    virt_status="AMD-V enabled"
  fi

  local iommu_status="Not detected in dmesg"
  if dmesg 2>/dev/null | grep -qE "DMAR-IR: Enabled IRQ remapping|AMD-Vi: Interrupt remapping enabled|IOMMU enabled|DMAR:.*IOMMU enabled"; then
    iommu_status="IOMMU / Interrupt remapping enabled"
  fi

  local group_count=0
  if [[ -d /sys/kernel/iommu_groups ]]; then
    group_count=$(find /sys/kernel/iommu_groups -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
  fi

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Virtualization & IOMMU Status" --msgbox \
    "CPU Virtualization: ${virt_status}\nIOMMU Remapping: ${iommu_status}\nIOMMU Groups Found: ${group_count}\n\nNote: If IOMMU is missing, check BIOS/UEFI (VT-d / AMD-Vi) and ensure kernel IOMMU flags are active." 14 70
}

enable_passthrough() {
  header_info

  # Clear warning about VM passthrough vs LXC container usage
  local warning_text="This tool configures vfio-pci to dedicate your GPU exclusively to Virtual Machines.\n\n"
  warning_text+="WARNING:\n"
  warning_text+="Do NOT use this if you want to share your GPU with LXC containers (for example, running Ollama or Plex via LXC),\n"
  warning_text+="as VFIO unbinds the host driver and disables access to /dev/dri and /dev/kfd.\n\n"
  warning_text+="Do you want to proceed with enabling GPU passthrough?"

  if ! whiptail --backtitle "Proxmox VE Helper Scripts" --title "GPU Passthrough Warning" --yesno "$warning_text" 16 76; then
    return
  fi

  header_info
  msg_info "Configuring GRUB parameters"
  backup_file "$GRUB_CONF"

  if lscpu | grep -q Intel; then
    grub_add_param "intel_iommu=on"
  elif lscpu | grep -q AMD; then
    grub_add_param "amd_iommu=on"
  fi
  grub_add_param "iommu=pt"

  msg_info "Updating GRUB"
  /usr/sbin/update-grub >/dev/null 2>&1
  msg_ok "Updated GRUB"

  msg_info "Configuring VFIO kernel modules"
  backup_file "$MODULES_CONF"
  add_module "vfio"
  add_module "vfio_iommu_type1"
  add_module "vfio_pci"
  if [[ -f "/lib/modules/$(uname -r)/kernel/drivers/vfio/vfio_virqfd.ko" ]] || \
     [[ -f "/lib/modules/$(uname -r)/kernel/drivers/vfio/vfio_virqfd.ko.zst" ]]; then
    add_module "vfio_virqfd"
  fi
  msg_ok "VFIO modules configured in $MODULES_CONF"

  msg_info "Scanning GPU PCI devices"
  ensure_vfio_conf
  backup_file "$VFIO_CONF"

  local lspci_output
  lspci_output=$(lspci -nn)

  local device_ids
  device_ids=$(echo "$lspci_output" | grep -Ei "vga|3d|display|audio" \
    | grep -i -e 'nvidia' -e 'AMD/ATI' \
    | sed -n 's/.*\[\([0-9a-fA-F]*:[0-9a-fA-F]*\)\].*/\1/p' \
    | paste -sd ',' -)

  if [[ -n "$device_ids" ]]; then
    msg_ok "Detected GPU PCI IDs: ${BL}${device_ids}${CL}"
    sed -i "/^options vfio-pci ids=/d" "$VFIO_CONF"
    echo "options vfio-pci ids=${device_ids}" >> "$VFIO_CONF"
  else
    msg_warn "No NVIDIA or AMD GPUs automatically detected"
  fi

  if echo "$lspci_output" | grep -Ei "vga|3d|display|audio" | grep -qi 'nvidia'; then
    msg_info "Adding NVIDIA driver softdeps"
    for drv in nouveau nvidia nvidiafb nvidia_drm drm; do
      remove_softdep "$drv"
      add_softdep "$drv"
    done
    msg_ok "Added NVIDIA softdeps"
  fi

  if echo "$lspci_output" | grep -Ei "vga|3d|display|audio" | grep -qi 'AMD/ATI'; then
    msg_info "Adding AMD driver softdeps"
    for drv in radeon amdgpu snd_hda_intel; do
      remove_softdep "$drv"
      add_softdep "$drv"
    done
    msg_ok "Added AMD softdeps"
  fi

  msg_info "Updating initramfs (this may take a minute)"
  /usr/sbin/update-initramfs -u >/dev/null 2>&1
  msg_ok "Updated initramfs"

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Setup Complete" --msgbox \
    "GPU passthrough configuration is complete!\n\nDetected IDs: ${device_ids:-None}\nConfig file: $VFIO_CONF\n\nPlease reboot the Proxmox host for changes to take effect." 12 70
}

verify_passthrough() {
  header_info
  msg_info "Verifying VFIO driver bindings"

  local gpu_status
  gpu_status=$(lspci -nnk 2>/dev/null | grep -A2 -e NVIDIA -e 'AMD/ATI' || true)

  if echo "$gpu_status" | grep -q 'vfio-pci'; then
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "GPU Passthrough Status: ACTIVE" --msgbox \
      "vfio-pci is bound to your GPU:\n\n${gpu_status}" 18 76
  else
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "GPU Passthrough Status: NOT BOUND" --msgbox \
      "vfio-pci is NOT currently bound to the GPU.\n\nCurrent status:\n${gpu_status:-No GPU detected}\n\nIf you recently ran setup, make sure you rebooted the host." 18 76
  fi
}

compile_vbios() {
  header_info

  if ! command -v gcc >/dev/null 2>&1; then
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "Missing Dependency" --msgbox \
      "gcc is required to compile the ACPI VBIOS extractor.\nPlease run: apt-get install -y build-essential" 10 65
    return
  fi

  if [[ ! -f /sys/firmware/acpi/tables/VFCT ]]; then
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "VFCT Table Missing" --msgbox \
      "/sys/firmware/acpi/tables/VFCT was not found.\nThis table is typically only available on systems with AMD GPUs." 10 68
    return
  fi

  if ! whiptail --backtitle "Proxmox VE Helper Scripts" --title "Compile AMD VBIOS" --yesno \
    "Extract AMD VBIOS ROM from ACPI VFCT table to /usr/share/kvm/?" 10 65; then
    return
  fi

  local tmpdir
  tmpdir=$(mktemp -d /tmp/vbios_extract.XXXXXX)

  cat << 'VBIOS_EOF' > "${tmpdir}/vbios.c"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef uint32_t ULONG;
typedef uint8_t UCHAR;
typedef uint16_t USHORT;

typedef struct {
    ULONG Signature;
    ULONG TableLength;
    UCHAR Revision;
    UCHAR Checksum;
    UCHAR OemId[6];
    UCHAR OemTableId[8];
    ULONG OemRevision;
    ULONG CreatorId;
    ULONG CreatorRevision;
} AMD_ACPI_DESCRIPTION_HEADER;

typedef struct {
    AMD_ACPI_DESCRIPTION_HEADER SHeader;
    UCHAR TableUUID[16];
    ULONG VBIOSImageOffset;
    ULONG Lib1ImageOffset;
    ULONG Reserved[4];
} UEFI_ACPI_VFCT;

typedef struct {
    ULONG PCIBus;
    ULONG PCIDevice;
    ULONG PCIFunction;
    USHORT VendorID;
    USHORT DeviceID;
    USHORT SSVID;
    USHORT SSID;
    ULONG Revision;
    ULONG ImageLength;
} VFCT_IMAGE_HEADER;

typedef struct {
    VFCT_IMAGE_HEADER VbiosHeader;
    UCHAR VbiosContent[1];
} GOP_VBIOS_CONTENT;

int main(int argc, char** argv) {
    FILE* fp_vfct;
    FILE* fp_vbios;
    UEFI_ACPI_VFCT* pvfct;
    char vbios_name[0x400];

    if (!(fp_vfct = fopen("/sys/firmware/acpi/tables/VFCT", "r"))) {
        perror(argv[0]);
        return -1;
    }
    if (!(pvfct = malloc(sizeof(UEFI_ACPI_VFCT)))) {
        perror(argv[0]);
        return -1;
    }
    if (sizeof(UEFI_ACPI_VFCT) != fread(pvfct, 1, sizeof(UEFI_ACPI_VFCT), fp_vfct)) {
        fprintf(stderr, "%s: failed to read VFCT header!\n", argv[0]);
        return -1;
    }

    ULONG offset = pvfct->VBIOSImageOffset;
    ULONG tbl_size = pvfct->SHeader.TableLength;

    if (!(pvfct = realloc(pvfct, tbl_size))) {
        perror(argv[0]);
        return -1;
    }
    if (tbl_size - sizeof(UEFI_ACPI_VFCT) != fread(pvfct + 1, 1, tbl_size - sizeof(UEFI_ACPI_VFCT), fp_vfct)) {
        fprintf(stderr, "%s: failed to read VFCT body!\n", argv[0]);
        return -1;
    }
    fclose(fp_vfct);

    while (offset < tbl_size) {
        GOP_VBIOS_CONTENT* vbios = (GOP_VBIOS_CONTENT*)((char*)pvfct + offset);
        VFCT_IMAGE_HEADER* vhdr = &vbios->VbiosHeader;
        if (!vhdr->ImageLength) break;

        snprintf(vbios_name, sizeof(vbios_name), "vbios_%x_%x.bin", vhdr->VendorID, vhdr->DeviceID);
        if (!(fp_vbios = fopen(vbios_name, "wb"))) {
            perror(argv[0]);
            return -1;
        }
        if (vhdr->ImageLength != fwrite(&vbios->VbiosContent, 1, vhdr->ImageLength, fp_vbios)) {
            fprintf(stderr, "%s: failed to dump vbios %x:%x\n", argv[0], vhdr->VendorID, vhdr->DeviceID);
            return -1;
        }
        fclose(fp_vbios);
        printf("Dumped vbios %x:%x -> %s\n", vhdr->VendorID, vhdr->DeviceID, vbios_name);
        offset += sizeof(VFCT_IMAGE_HEADER);
        offset += vhdr->ImageLength;
    }
    return 0;
}
VBIOS_EOF

  msg_info "Compiling and extracting VBIOS"
  gcc "${tmpdir}/vbios.c" -o "${tmpdir}/vbios"
  pushd "$tmpdir" >/dev/null
  ./vbios
  popd >/dev/null

  local count=0
  for bin in "${tmpdir}"/vbios_*.bin; do
    [[ -f "$bin" ]] || continue
    local bname
    bname=$(basename "$bin")
    cp "$bin" "/usr/share/kvm/${bname}"
    count=$((count + 1))
  done
  rm -rf "$tmpdir"

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "VBIOS Extraction Complete" --msgbox \
    "Extracted ${count} VBIOS ROM file(s) into /usr/share/kvm/.\n\nYou can use them in Proxmox VM hardware options or with 'romfile='." 12 70
}

revert_changes() {
  header_info

  if ! whiptail --backtitle "Proxmox VE Helper Scripts" --title "Revert Passthrough Changes" --yesno \
    "This will remove VFIO kernel parameters from GRUB, /etc/modules, and /etc/modprobe.d/vfio.conf.\n\nProceed?" 12 70; then
    return
  fi

  header_info
  msg_info "Reverting GRUB parameters"
  backup_file "$GRUB_CONF"
  grub_remove_param "iommu=pt"
  grub_remove_param "intel_iommu=on"
  grub_remove_param "amd_iommu=on"
  /usr/sbin/update-grub >/dev/null 2>&1
  msg_ok "Reverted GRUB"

  msg_info "Reverting modules"
  backup_file "$MODULES_CONF"
  remove_module "vfio"
  remove_module "vfio_iommu_type1"
  remove_module "vfio_pci"
  remove_module "vfio_virqfd"
  msg_ok "Reverted modules in $MODULES_CONF"

  if [[ -f "$VFIO_CONF" ]]; then
    backup_file "$VFIO_CONF"
    sed -i "/^options vfio-pci ids=/d" "$VFIO_CONF"
    for drv in nouveau nvidia nvidiafb nvidia_drm drm radeon amdgpu snd_hda_intel; do
      remove_softdep "$drv"
    done
    msg_ok "Cleaned $VFIO_CONF"
  fi

  msg_info "Updating initramfs"
  /usr/sbin/update-initramfs -u >/dev/null 2>&1
  msg_ok "Updated initramfs"

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Revert Complete" --msgbox \
    "GPU passthrough configuration has been reverted.\n\nPlease reboot the host for changes to take effect." 10 65
}

# Main interactive loop
while true; do
  header_info
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE GPU Passthrough Helper" --menu \
    "Choose an option:" 16 70 6 \
    "1" "Check CPU Virtualization & IOMMU" \
    "2" "Enable GPU Passthrough (for VMs)" \
    "3" "Verify GPU Passthrough Status" \
    "4" "Compile AMD VBIOS ROM from ACPI" \
    "5" "Revert Passthrough Changes" \
    "6" "Exit" 3>&1 1>&2 2>&3) || exit 0

  case "$CHOICE" in
    1) check_virtualization ;;
    2) enable_passthrough ;;
    3) verify_passthrough ;;
    4) compile_vbios ;;
    5) revert_changes ;;
    6) clear; exit 0 ;;
    *) exit 0 ;;
  esac
done
