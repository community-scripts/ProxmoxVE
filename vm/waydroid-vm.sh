#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://waydro.id/

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")
load_functions

APP="Waydroid"
APP_TYPE="vm"
NSAPP="waydroid-vm"
var_os="ubuntu"
var_version="24.04"
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
METHOD=""
THIN="discard=on,ssd=1,"
USE_CLOUD_INIT="no"
OS_CHOICE="ubuntu2404"
OS_LABEL="Ubuntu 24.04 LTS (Noble Numbat)"
OS_CODENAME="noble"
WAYDROID_PREINSTALLED="no"
WAYDROID_FIRSTBOOT_MARKER=""

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
vm_require_tools virt-customize jq

function select_os() {
  if [[ -n "${1:-}" ]]; then
    OS_CHOICE="$1"
  elif [[ "${VM_UNATTENDED:-0}" == "1" ]]; then
    OS_CHOICE="${VM_OS_VERSION:-ubuntu2404}"
  elif vm_dialog radiolist "OS SELECTION" \
    "Choose the base operating system:" --cancel-button Exit-Script 12 68 2 \
    "ubuntu2404" "Ubuntu 24.04 LTS (Noble Numbat)" ON \
    "debian13" "Debian 13 (Trixie)" OFF; then
    OS_CHOICE="$VM_DIALOG_RESULT"
  else
    exit_script
  fi

  case "$OS_CHOICE" in
  ubuntu2404)
    OS_LABEL="Ubuntu 24.04 LTS (Noble Numbat)"
    OS_CODENAME="noble"
    var_os="ubuntu"
    var_version="24.04"
    ;;
  debian13)
    OS_LABEL="Debian 13 (Trixie)"
    OS_CODENAME="trixie"
    var_os="debian"
    var_version="13"
    ;;
  *)
    msg_error "Unsupported OS '${OS_CHOICE}' (expected ubuntu2404 or debian13)"
    exit 1
    ;;
  esac
  echo -e "${OS}${BOLD}${DGN}Base OS: ${BGN}${OS_LABEL}${CL}"
}

function default_settings() {
  select_os "${VM_OS_VERSION:-}"
  VMID=$(get_valid_nextid)
  vm_apply_machine_type "q35"
  DISK_SIZE="20G"
  DISK_CACHE=""
  HN="waydroid"
  CPU_TYPE=" -cpu host"
  CORE_COUNT="4"
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
  vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
  vm_prompt_machine_type "q35"
  vm_prompt_disk_size "20G" "Set Disk Size in GiB (min. 20 recommended)"
  vm_prompt_disk_cache "none"
  vm_prompt_hostname "waydroid"
  vm_prompt_cpu_model "host"
  vm_prompt_cpu_cores "4"
  vm_prompt_ram "4096"
  vm_prompt_bridge "vmbr0"
  vm_prompt_mac "$GEN_MAC"
  vm_prompt_vlan
  vm_prompt_mtu
  vm_prompt_keyboard
  vm_prompt_verbose "no"
  vm_prompt_start_vm "yes"

  if vm_confirm_advanced_settings "Ready to create a ${OS_LABEL} Waydroid VM?"; then
    echo -e "${CREATING}${BOLD}${DGN}Creating a ${OS_LABEL} Waydroid VM using the above advanced settings${CL}"
  else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

vm_start_script "Use Default Settings?\n\nDefaults:\n• 4 CPU Cores\n• 4 GB RAM\n• 20 GB Disk" 13 58
CLOUDINIT_REQUIRED=1
# Android does not start for root, so unattended runs get the image's usual user.
[[ "${VM_UNATTENDED:-0}" == "1" ]] && export CLOUDINIT_USER="${CLOUDINIT_USER:-$var_os}"
if [[ "$OS_CHOICE" == "debian13" ]]; then
  vm_prompt_cloud_init "debian"
else
  vm_prompt_cloud_init "ubuntu"
fi
if [[ "$USE_CLOUD_INIT" != "yes" ]]; then
  msg_error "Waydroid cloud images require Cloud-Init credentials."
  exit 1
fi
post_to_api_vm

vm_select_storage "$HN"
vm_define_disk_references 2

case "$OS_CHOICE" in
ubuntu2404) URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img" ;;
debian13) URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2" ;;
esac

msg_info "Retrieving the URL for the ${OS_LABEL} Cloud Image"
msg_ok "${CL}${BL}${URL}${CL}"

CACHE_FILE="$(vm_image_cache_path "$URL")"
MIN_IMAGE_BYTES=$((100 * 1024 * 1024))
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes "$MIN_IMAGE_BYTES" || exit 115

WORK_FILE="$TEMP_DIR/waydroid.qcow2"
cp "$CACHE_FILE" "$WORK_FILE"

export LIBGUESTFS_BACKEND_SETTINGS=dns=8.8.8.8,1.1.1.1

# Ubuntu ships binder_linux in linux-modules-extra, which the cloud kernel leaves out.
# Run in the image, on first boot and once per boot for each installed kernel:
# Cloud-Init's first-boot upgrade and later updates bring kernels without it. Not
# from waydroid-container itself: needrestart restarts that inside apt's lock.
WAYDROID_BINDER_TMP="$TEMP_DIR/waydroid-binder"
cat >"$WAYDROID_BINDER_TMP" <<'BINDER'
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1
grep -q '^ID=ubuntu' /etc/os-release || exit 0
rc=0
for kernel in /boot/vmlinuz-*; do
  version="${kernel#/boot/vmlinuz-}"
  find "/lib/modules/${version}" -name 'binder_linux.ko*' 2>/dev/null | grep -q . && continue
  apt-get -o DPkg::Lock::Timeout=300 install -y "linux-modules-extra-${version}" || rc=1
done
exit "$rc"
BINDER
WAYDROID_BINDER_UNIT_TMP="$TEMP_DIR/waydroid-binder.service"
cat >"$WAYDROID_BINDER_UNIT_TMP" <<'UNIT'
[Unit]
Description=Binder module for every installed kernel
After=network-online.target
Wants=network-online.target
Before=waydroid-container.service

[Service]
Type=oneshot
ExecStart=-/usr/local/sbin/waydroid-binder
ExecStart=/sbin/modprobe binder_linux
RemainAfterExit=yes
TimeoutStartSec=15min

[Install]
WantedBy=multi-user.target
UNIT

# `weston` on the VM console opens Android full-screen and returns to the
# console when it is closed; until Waydroid is initialized it opens a terminal.
WESTON_INI_TMP="$TEMP_DIR/weston.ini"
cat >"$WESTON_INI_TMP" <<'INI'
[core]
idle-time=0

[autolaunch]
path=/usr/local/bin/waydroid-ui
watch=true
INI
WAYDROID_UI_TMP="$TEMP_DIR/waydroid-ui"
cat >"$WAYDROID_UI_TMP" <<'UI'
#!/bin/sh
if [ -f /var/lib/waydroid/lxc/waydroid/config ]; then
  exec waydroid show-full-ui
fi
exec weston-terminal
UI
WAYDROID_STATUS_TMP="$TEMP_DIR/waydroid-status.sh"
cat >"$WAYDROID_STATUS_TMP" <<'STATUS'
if [ ! -f /var/lib/waydroid/lxc/waydroid/config ]; then
  echo "Waydroid is still being set up: tail -f /var/log/waydroid-install.log"
elif [ "$(id -u)" = 0 ]; then
  # PipeWire's user units refuse root, and Waydroid's container mounts its audio socket.
  echo "Android does not start for root; log in as a normal user to run weston (adduser creates one)."
fi
STATUS

vm_customize "Waydroid setup files" "$WORK_FILE" \
  --mkdir /etc/xdg/weston \
  --upload "${WAYDROID_BINDER_TMP}:/usr/local/sbin/waydroid-binder" \
  --chmod "0755:/usr/local/sbin/waydroid-binder" \
  --upload "${WAYDROID_BINDER_UNIT_TMP}:/etc/systemd/system/waydroid-binder.service" \
  --upload "${WESTON_INI_TMP}:/etc/xdg/weston/weston.ini" \
  --upload "${WAYDROID_UI_TMP}:/usr/local/bin/waydroid-ui" \
  --chmod "0755:/usr/local/bin/waydroid-ui" \
  --upload "${WAYDROID_STATUS_TMP}:/etc/profile.d/waydroid-status.sh" \
  --run-command "grep -qxF binder_linux /etc/modules || echo 'binder_linux' >> /etc/modules" \
  --run-command "echo 'options binder_linux devices=binder,hwbinder,vndbinder' > /etc/modprobe.d/waydroid.conf" \
  --run-command "systemctl enable waydroid-binder.service" || exit 1

# The cloud image has well under 1 GB free, too little for Weston, Waydroid and the kernel modules.
msg_info "Expanding the root filesystem to ${DISK_SIZE}"
vm_expand_image "$WORK_FILE" "$DISK_SIZE" || true

# Recommends would add lxc templates, debootstrap, qemu-utils and VA drivers
# (a third of the download); the GL driver and the audio session manager stay.
WESTON_PKGS="curl ca-certificates qemu-guest-agent weston libgl1-mesa-dri"
WAYDROID_PKGS="waydroid wireplumber"
APT_INSTALL="DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends"

msg_info "Installing Weston in the image"
if vm_customize "Weston" "$WORK_FILE" \
  --run-command "apt-get update" \
  --run-command "${APT_INSTALL} ${WESTON_PKGS}"; then
  msg_ok "Installed Weston in the image"
  msg_info "Installing Waydroid in the image"
  if vm_customize "Waydroid" "$WORK_FILE" \
    --run-command "/usr/local/sbin/waydroid-binder" \
    --run-command "bash -o pipefail -c 'curl -fsSL https://repo.waydro.id | bash -s ${OS_CODENAME}'" \
    --run-command "${APT_INSTALL} ${WAYDROID_PKGS}" \
    --run-command "systemctl enable waydroid-container"; then
    WAYDROID_PREINSTALLED="yes"
    msg_ok "Installed Waydroid in the image"
  fi
fi
[[ "$WAYDROID_PREINSTALLED" == "yes" ]] || msg_warn "Installing in the image failed; the VM installs it on first boot."

vm_prepare_cloud_image "$WORK_FILE" "$HN" || true

# `waydroid init` downloads Android and needs the guest's binder driver, so it
# cannot run in the image.
WAYDROID_FIRSTBOOT_TMP="$TEMP_DIR/waydroid-firstboot.sh"
cat >"$WAYDROID_FIRSTBOOT_TMP" <<FIRSTBOOT
#!/usr/bin/env bash
set -Eeuo pipefail
exec >>/var/log/waydroid-install.log 2>&1

echo "[\$(date)] Setting up Waydroid"
# A package step that failed in the image leaves dpkg half done.
dpkg --configure -a
apt-get install -f -y
if ! command -v waydroid >/dev/null 2>&1; then
  apt-get update
  ${APT_INSTALL} ${WESTON_PKGS}
  curl -fsSL https://repo.waydro.id | bash -s ${OS_CODENAME}
  ${APT_INSTALL} ${WAYDROID_PKGS}
fi
/usr/local/sbin/waydroid-binder
modprobe binder_linux
# Unbuffered, the download progress reaches the log as it happens; the host shows it.
PYTHONUNBUFFERED=1 waydroid init
systemctl restart waydroid-container
echo "[\$(date)] Waydroid is ready"
FIRSTBOOT

vm_firstboot_unit "$WORK_FILE" waydroid-firstboot "$WAYDROID_FIRSTBOOT_TMP" \
  --description "Waydroid first boot setup" \
  --cloud-init yes || exit 1
WAYDROID_FIRSTBOOT_MARKER="$VM_FIRSTBOOT_MARKER"

vm_claim_vmid
msg_info "Creating a ${OS_LABEL} Waydroid VM"
qm create "$VMID" -agent 1${MACHINE} -tablet 0 -bios ovmf${CPU_TYPE} -cores "$CORE_COUNT" -memory "$RAM_SIZE" \
  -name "$HN" -tags community-script,waydroid -net0 "virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU" -onboot 1 -ostype l26 -scsihw virtio-scsi-pci
vm_mark_created
msg_ok "Created a ${OS_LABEL} Waydroid VM ${CL}${BL}(${HN})"

vm_alloc_efi_disk "$DISK0"
vm_import_disk "$VMID" "$WORK_FILE" "$STORAGE"

DISK_OPTIONS="${DISK_CACHE}${THIN}"
DISK_OPTIONS="${DISK_OPTIONS%,}"
ROOT_DISK="$VM_IMPORTED_DISK"
[[ -n "$DISK_OPTIONS" ]] && ROOT_DISK="${ROOT_DISK},${DISK_OPTIONS}"

qm set "$VMID" \
  --efidisk0 "${DISK0_REF}${FORMAT}" \
  --scsi0 "$ROOT_DISK" \
  --boot order=scsi0 \
  --serial0 socket >/dev/null
vm_resize_disk "scsi0" "$DISK_SIZE"
set_description

vm_provision "$VMID"
if [[ -n "${CLOUDINIT_SSH_KEYS:-}" ]]; then
  $STD qm set "$VMID" --sshkeys "$CLOUDINIT_SSH_KEYS"
fi

vm_start_vm "Waydroid VM"
vm_wait_for_ip 120 || true

# Waits as long as the guest's logs keep growing: the Android download runs at
# whatever speed the SourceForge mirror gives, seven minutes or forty.
WAYDROID_STATE="pending"
if [[ "$START_VM" == "yes" ]]; then
  msg_info "Setting up Waydroid in the VM"
  WAYDROID_PROBE="if [ -f '${WAYDROID_FIRSTBOOT_MARKER}' ]; then echo ready
elif systemctl is-failed --quiet waydroid-firstboot.service; then echo failed
else
  [ \"\$(systemctl is-active waydroid-firstboot.service)\" = activating ] && echo setup || echo cloud-init
  stat -c %s /var/log/cloud-init-output.log /var/log/waydroid-install.log 2>/dev/null | tr '\n' ' '; echo
  tail -c 300 /var/log/waydroid-install.log 2>/dev/null | tr '\r' '\n' | grep -o '[0-9.]* MB/[0-9.]* MB' | tail -n 1
fi"
  WAYDROID_LAST_SIZES="" WAYDROID_SHOWN="" WAYDROID_IDLE=0
  while ((WAYDROID_IDLE < 600)); do
    WAYDROID_STATUS="$(vm_guest_exec "$VMID" 15 -- sh -c "$WAYDROID_PROBE" 2>/dev/null || true)"
    case "${WAYDROID_STATUS%%$'\n'*}" in
    ready | failed)
      WAYDROID_STATE="${WAYDROID_STATUS%%$'\n'*}"
      break
      ;;
    setup | cloud-init)
      WAYDROID_SIZES="$(sed -n 2p <<<"$WAYDROID_STATUS")"
      WAYDROID_BYTES="$(sed -n 3p <<<"$WAYDROID_STATUS")"
      if [[ -n "$WAYDROID_BYTES" ]]; then
        WAYDROID_TEXT="Downloading Android in the VM (${WAYDROID_BYTES%%/*} of ${WAYDROID_BYTES##*/})"
      elif [[ "$WAYDROID_STATUS" == cloud-init* ]]; then
        WAYDROID_TEXT="Waiting for Cloud-Init's package upgrade in the VM"
      else
        WAYDROID_TEXT="Setting up Waydroid in the VM"
      fi
      if [[ "$WAYDROID_TEXT" != "$WAYDROID_SHOWN" ]]; then
        start_spinner "$WAYDROID_TEXT"
        WAYDROID_SHOWN="$WAYDROID_TEXT"
      fi
      if [[ "$WAYDROID_SIZES" != "$WAYDROID_LAST_SIZES" ]]; then
        WAYDROID_LAST_SIZES="$WAYDROID_SIZES"
        WAYDROID_IDLE=0
      fi
      ;;
    esac
    sleep 5
    WAYDROID_IDLE=$((WAYDROID_IDLE + 5))
  done
  case "$WAYDROID_STATE" in
  ready) msg_ok "Waydroid is ready" ;;
  failed) msg_warn "Waydroid setup failed in the VM; it retries on the next boot. Log: /var/log/waydroid-install.log" ;;
  *) msg_warn "No progress in the VM for 10 minutes; the setup goes on there. Log: /var/log/waydroid-install.log" ;;
  esac
fi

display_cloud_init_info "$VMID" "$HN"

case "$WAYDROID_STATE" in
ready) WAYDROID_SUMMARY="ready" ;;
failed) WAYDROID_SUMMARY="setup failed, see /var/log/waydroid-install.log" ;;
*) WAYDROID_SUMMARY="being set up on first boot, see /var/log/waydroid-install.log" ;;
esac
vm_print_summary \
  "OS=${OS_LABEL}" \
  "Waydroid=${WAYDROID_SUMMARY}" \
  "Documentation=https://docs.waydro.id/"

WAYDROID_STEPS=()
case "$WAYDROID_STATE" in
failed) WAYDROID_STEPS+=("See why in /var/log/waydroid-install.log; the setup runs again on the next boot of the VM.") ;;
pending) WAYDROID_STEPS+=("Wait for the setup to finish: tail -f /var/log/waydroid-install.log") ;;
esac
if [[ "${CLOUDINIT_USER:-root}" == "root" ]]; then
  WAYDROID_STEPS+=("Android does not start for root. Log in on the VM, create a user (adduser NAME) and use that one below.")
  WAYDROID_LOGIN="the new user"
else
  WAYDROID_LOGIN="${CLOUDINIT_USER}"
fi
WAYDROID_STEPS+=(
  "Open the VM's Console (noVNC) in Proxmox, log in as ${WAYDROID_LOGIN} and type weston. Android opens full screen; closing it returns to the console."
  "Android only shows on noVNC; the serial console (xterm.js) has no display."
)
vm_next_steps "${WAYDROID_STEPS[@]}"

case "$WAYDROID_STATE" in
ready) vm_finish "Waydroid VM is ready." ;;
failed) vm_finish "VM created, but the Waydroid setup in it failed." ;;
*) vm_finish "VM created. Waydroid setup continues in the VM." ;;
esac
