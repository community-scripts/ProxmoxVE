#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
load_functions
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "iommu-setup" "pve"

function header_info {
  clear
  cat <<"EOF"
    ____  ____  __  _____  __  ____    _____      __
   /  _/ / __ \/  |/  /  |/  / / / /  / ___/___  / /___  ______
   / /  / / / / /|_/ / /|_/ / / / /   \__ \/ _ \/ __/ / / / __ \
 _/ /  / /_/ / /  / / /  / / /_/ /   ___/ /  __/ /_/ /_/ / /_/ /
/___/  \____/_/  /_/_/  /_/\____/   /____/\___/\__/\__,_/ .___/
                                                       /_/
EOF
}

header_info

# Guards
if [ "$(id -u)" -ne 0 ]; then
  msg_error "This script must be run as root."
  exit 1
fi
if ! command -v pveversion >/dev/null 2>&1; then
  msg_error "No Proxmox VE detected!"
  exit 1
fi
if ! pveversion | grep -Eq "pve-manager/(8\.[0-4]|9\.[0-9]+)(\.[0-9]+)*"; then
  msg_error "This version of Proxmox Virtual Environment is not supported."
  msg_error "Requires Proxmox Virtual Environment Version 8.0-8.4 or 9.x."
  exit 1
fi
# systemd-detect-virt prints "none" but exits non-zero on bare metal, so a
# `|| echo none` fallback would duplicate the value; capture output as-is.
virt=$(systemd-detect-virt 2>/dev/null)
if [ -n "$virt" ] && [ "$virt" != "none" ]; then
  msg_error "IOMMU/PCI passthrough must be configured on bare metal. Detected: $virt"
  exit 1
fi

# Whether a kernel parameter is already present in a cmdline string
has_token() {
  case " $1 " in
  *" $2 "*) return 0 ;;
  *) return 1 ;;
  esac
}

# Detect CPU vendor and the matching kernel parameters
cpu_vendor=$(lscpu | grep -oP 'Vendor ID:\s*\K\S+' | head -n 1)
case "$cpu_vendor" in
GenuineIntel) IOMMU_PARAMS=("intel_iommu=on" "iommu=pt") ;;
AuthenticAMD) IOMMU_PARAMS=("amd_iommu=on" "iommu=pt") ;;
*)
  msg_error "Unsupported CPU vendor: ${cpu_vendor:-unknown}"
  exit 1
  ;;
esac

# Report current IOMMU state
iommu_active="no"
if [ -d /sys/kernel/iommu_groups ] && [ -n "$(ls -A /sys/kernel/iommu_groups 2>/dev/null)" ]; then
  iommu_active="yes"
fi

echo -e "${BL}CPU vendor:${CL}      ${cpu_vendor}"
echo -e "${BL}IOMMU active:${CL}    $([ "$iommu_active" = "yes" ] && echo -e "${GN}yes${CL}" || echo -e "${RD}no${CL}")"
echo -e "${BL}Kernel params:${CL}   ${IOMMU_PARAMS[*]}"
echo

if [ "$iommu_active" = "yes" ]; then
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "IOMMU Already Active" \
    --yesno "IOMMU already appears to be active on this host.\n\nDo you still want to (re)apply the kernel parameters and vfio modules?" 12 70 || {
    echo -e "${GN}Nothing to do.${CL}"
    exit 0
  }
else
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Enable IOMMU / PCI(e) Passthrough" \
    --yesno "This will enable IOMMU for PCI(e) passthrough by:\n\n - adding '${IOMMU_PARAMS[*]}' to the kernel command line\n - loading the vfio kernel modules\n\nA reboot is required afterwards. A backup of the modified boot config is created.\n\nProceed?" 16 74 || exit 0
fi

# Determine the boot configuration in use
# proxmox-boot-tool managed systems (ZFS / UEFI) use /etc/kernel/cmdline,
# everything else uses GRUB via /etc/default/grub.
if command -v proxmox-boot-tool >/dev/null 2>&1 && [ -f /etc/kernel/cmdline ]; then
  BOOT_MODE="systemd-boot"
else
  BOOT_MODE="grub"
fi

apply_grub() {
  local file="/etc/default/grub" current merged
  cp -a "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"

  if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$file"; then
    current=$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT=//p' "$file" | tail -1)
    current="${current%\"}"
    current="${current#\"}"
  else
    current=""
  fi

  merged="$current"
  for tok in "${IOMMU_PARAMS[@]}"; do
    has_token "$merged" "$tok" || merged="${merged:+$merged }$tok"
  done

  if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$file"; then
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${merged}\"|" "$file"
  else
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"${merged}\"" >>"$file"
  fi

  update-grub &>/dev/null
}

apply_systemd_boot() {
  local file="/etc/kernel/cmdline" current merged
  cp -a "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
  current=$(tr -d '\n' <"$file")

  merged="$current"
  for tok in "${IOMMU_PARAMS[@]}"; do
    has_token "$merged" "$tok" || merged="${merged:+$merged }$tok"
  done

  echo "$merged" >"$file"
  proxmox-boot-tool refresh &>/dev/null
}

msg_info "Applying kernel parameters via ${BOOT_MODE}"
if [ "$BOOT_MODE" = "systemd-boot" ]; then
  apply_systemd_boot
else
  apply_grub
fi
msg_ok "Applied kernel parameters (${BOOT_MODE})"

# Load vfio modules at boot (vfio_virqfd was merged into the core in
# kernel 6.2+, so it is intentionally not added here)
msg_info "Configuring vfio modules"
for m in vfio vfio_iommu_type1 vfio_pci; do
  grep -qxF "$m" /etc/modules 2>/dev/null || echo "$m" >>/etc/modules
done
msg_ok "Configured vfio modules"

echo -e "\n${GN}IOMMU configuration written.${CL}"
echo -e "${YW}A reboot is required to activate IOMMU.${CL}"
echo -e "After rebooting, verify with: ${BL}dmesg | grep -e DMAR -e IOMMU${CL}"
echo -e "and list groups with:        ${BL}find /sys/kernel/iommu_groups/ -type l${CL}\n"
