#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
load_functions
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "storage-share-helper" "pve"

set -eEuo pipefail

function header_info() {
  clear
  cat <<"EOF"
    _____ __                                 ___    _________ 
   / ___// /_____  _________ _____ ____     /   |  /  _/ __ \
   \__ \/ __/ __ \/ ___/ __ `/ __ `/ _ \   / /| |  / // / / /
  ___/ / /_/ /_/ / /  / /_/ / /_/ /  __/  / ___ |_/ // /_/ / 
 /____/\__/\____/_/   \__,_/\__, /\___/  /_/  |_/___/_____/  
                            /____/                            

 Proxmox Storage Allrounder
 SMB | NFS | iSCSI | LVM-on-iSCSI | LXC Mountpoints | Host Shares
EOF
}

pause() {
  read -r -p "Press Enter to continue..." _
}

require_pve() {
  if ! command -v pct >/dev/null 2>&1 || ! command -v pvesm >/dev/null 2>&1; then
    msg_error "This script must run on a Proxmox VE host (pct/pvesm missing)."
    exit 1
  fi
}

ensure_packages() {
  local packages=()

  command -v whiptail >/dev/null 2>&1 || packages+=("whiptail")
  command -v mount.cifs >/dev/null 2>&1 || packages+=("cifs-utils")
  command -v showmount >/dev/null 2>&1 || packages+=("nfs-common")
  command -v iscsiadm >/dev/null 2>&1 || packages+=("open-iscsi")

  if [[ ${#packages[@]} -gt 0 ]]; then
    msg_info "Installing required packages: ${packages[*]}"
    apt update >/dev/null 2>&1
    apt install -y "${packages[@]}" >/dev/null 2>&1
    msg_ok "Dependencies installed"
  fi
}

confirm_start() {
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Share Allrounder" \
    --yesno "This AIO wizard can test and configure SMB/NFS/iSCSI, create/remove Proxmox storages, manage LXC mountpoints and optionally create host shares. Proceed?" 13 100
}

read_input() {
  local title="$1"
  local prompt="$2"
  local default_value="${3:-}"

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --inputbox "$prompt" 11 100 "$default_value" 3>&1 1>&2 2>&3
}

read_password() {
  local title="$1"
  local prompt="$2"

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --passwordbox "$prompt" 11 100 3>&1 1>&2 2>&3
}

confirm_yes_no() {
  local title="$1"
  local prompt="$2"
  local height="${3:-11}"
  local width="${4:-100}"

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --yesno "$prompt" "$height" "$width"
}

# Destructive confirmation: defaults to "No" so a stray Enter never removes anything.
confirm_danger() {
  local title="$1"
  local prompt="$2"
  local height="${3:-15}"
  local width="${4:-100}"

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --defaultno --yesno "$prompt" "$height" "$width"
}

# Shown before slow data gathering. Goes to stderr: inside $(...) captures, stdout is
# swallowed — stderr is the real terminal.
show_loading() {
  echo -e "${YW}Loading... gathering data, this can take a moment (CTRL+C to abort)${CL}" >&2
}

# Info popup that stays visible inside $(...) captures: whiptail draws its UI on
# stdout, so without 1>&2 the dialog would be captured and the script appears hung.
notice_box() {
  local title="$1"
  local text="$2"
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --msgbox "$text" 10 80 1>&2
}

# Interactive container picker (read-only): returns the chosen CTID on stdout.
pick_container() {
  local title="$1"
  local -a rows=()
  local ctid status name label

  show_loading
  while IFS=$'\t' read -r ctid status name; do
    [[ -z "$ctid" ]] && continue
    label=$(printf '%-58s' "${name:-<no-name>} [${status}]")
    rows+=("$ctid" "$label")
  done < <(pct list 2>/dev/null | awk 'NR>1 {print $1"\t"$2"\t"$NF}')

  if [[ ${#rows[@]} -eq 0 ]]; then
    notice_box "$title" "No LXC containers found on this host."
    return 1
  fi

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --menu "Select a container:" 24 80 16 "${rows[@]}" 3>&1 1>&2 2>&3
}

# Interactive multi-select picker over ALL mountpoints across ALL containers (read-only).
# Returns chosen entries as "<ctid>:<mpX>" tokens on stdout.
# Reads /etc/pve/lxc/*.conf directly (one 'pct config' per CT is far too slow);
# awk stops at the first '[section]' so snapshot mp entries are not listed.
pick_all_mountpoints_multi() {
  local title="$1"
  local -a rows=()
  local conf ctid name line key def label

  show_loading
  for conf in /etc/pve/lxc/*.conf; do
    [[ -e "$conf" ]] || continue
    ctid="$(basename "$conf" .conf)"
    name=$(awk '/^\[/{exit} $1=="hostname:"{print $2; exit}' "$conf")
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      key="${line%%:*}"
      def="${line#*: }"
      label=$(printf '%-86s' "CT ${ctid} ${name:-<no-name>} | ${key}: ${def}")
      rows+=("${ctid}:${key}" "$label" "OFF")
    done < <(awk '/^\[/{exit} /^mp[0-9]+:/{print}' "$conf")
  done

  if [[ ${#rows[@]} -eq 0 ]]; then
    notice_box "$title" "No LXC mountpoints found on any container."
    return 1
  fi

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --checklist "Select mountpoint(s) to remove across all containers (Space to toggle, Enter to confirm):" \
    24 112 16 "${rows[@]}" 3>&1 1>&2 2>&3
}

# Interactive multi-select storage picker (read-only): returns chosen storage IDs on stdout.
pick_storages_multi() {
  local title="$1"
  local -a rows=()
  local stype sid label

  show_loading
  while read -r stype sid; do
    [[ -z "$sid" ]] && continue
    label=$(printf '%-58s' "[${stype}]")
    rows+=("$sid" "$label" "OFF")
  done < <(awk -F': ' '/^[a-z]+: /{print $1, $2}' /etc/pve/storage.cfg 2>/dev/null)

  if [[ ${#rows[@]} -eq 0 ]]; then
    notice_box "$title" "No storages found in /etc/pve/storage.cfg."
    return 1
  fi

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --checklist "Select storage(s) to remove (Space to toggle, Enter to confirm):" \
    24 80 16 "${rows[@]}" 3>&1 1>&2 2>&3
}

# Interactive multi-select container picker (read-only): returns chosen CTIDs on stdout.
pick_containers_multi() {
  local title="$1"
  local -a rows=()
  local ctid status name label

  show_loading
  while IFS=$'\t' read -r ctid status name; do
    [[ -z "$ctid" ]] && continue
    label=$(printf '%-58s' "${name:-<no-name>} [${status}]")
    rows+=("$ctid" "$label" "OFF")
  done < <(pct list 2>/dev/null | awk 'NR>1 {print $1"\t"$2"\t"$NF}')

  if [[ ${#rows[@]} -eq 0 ]]; then
    notice_box "$title" "No LXC containers found on this host."
    return 1
  fi

  whiptail --backtitle "Proxmox VE Helper Scripts" --title "$title" \
    --checklist "Select one or more containers (Space to toggle, Enter to confirm):" \
    24 80 16 "${rows[@]}" 3>&1 1>&2 2>&3
}

manual_smb_test() {
  header_info
  local server share username password domain vers mount_dir mount_opts

  server=$(read_input "SMB Test" "SMB server/IP (e.g. 10.0.1.9)") || return
  share=$(read_input "SMB Test" "Share name (without leading //)" "Proxmox") || return
  username=$(read_input "SMB Test" "Username" "proxmox") || return
  password=$(read_password "SMB Test" "Password for ${username}") || return
  domain=$(read_input "SMB Test" "Domain/Workgroup (optional, leave empty if not needed)") || return
  vers=$(read_input "SMB Test" "SMB version (e.g. 3.0, 3.1.1)" "3.1.1") || return
  mount_dir="/mnt/test-smb"

  mkdir -p "$mount_dir"

  mount_opts="username=${username},password=${password},vers=${vers},sec=ntlmssp"
  if [[ -n "$domain" ]]; then
    mount_opts+=";domain=${domain}"
  fi

  msg_info "Testing SMB mount on ${mount_dir}"
  if mount -t cifs "//${server}/${share}" "$mount_dir" -o "${mount_opts//;/,}" >/dev/null 2>&1; then
    touch "${mount_dir}/smb-test-$(date +%s)" >/dev/null 2>&1 || true
    umount "$mount_dir" >/dev/null 2>&1 || true
    msg_ok "SMB test successful"
  else
    msg_error "SMB test failed. Check network/firewall/credentials/share permissions."
  fi

  pause
}

manual_nfs_test() {
  header_info
  local server export_path mount_dir

  server=$(read_input "NFS Test" "NFS server/IP (e.g. 10.0.6.159)") || return
  export_path=$(read_input "NFS Test" "NFS export path (e.g. /srv/proxmox-nfs)") || return
  mount_dir="/mnt/test-nfs"

  mkdir -p "$mount_dir"

  msg_info "Testing NFS mount on ${mount_dir}"
  if mount -t nfs "${server}:${export_path}" "$mount_dir" >/dev/null 2>&1; then
    touch "${mount_dir}/nfs-test-$(date +%s)" >/dev/null 2>&1 || true
    umount "$mount_dir" >/dev/null 2>&1 || true
    msg_ok "NFS test successful"
  else
    msg_error "NFS test failed. Check export/firewall/network permissions."
  fi

  pause
}

manual_iscsi_discovery() {
  header_info
  local portal

  portal=$(read_input "iSCSI Discovery" "iSCSI portal IP/FQDN (e.g. 10.0.1.20)") || return
  msg_info "Running iSCSI target discovery on ${portal}"
  if iscsiadm -m discovery -t sendtargets -p "$portal"; then
    msg_ok "iSCSI discovery completed"
  else
    msg_error "iSCSI discovery failed"
  fi

  pause
}

add_smb_storage() {
  header_info
  local storage_id server share username password content nodes options

  storage_id=$(read_input "Add SMB/CIFS Storage" "Storage ID (unique, e.g. smb-media)") || return
  server=$(read_input "Add SMB/CIFS Storage" "SMB server/IP") || return
  share=$(read_input "Add SMB/CIFS Storage" "Share name (without //)") || return
  username=$(read_input "Add SMB/CIFS Storage" "Username") || return
  password=$(read_password "Add SMB/CIFS Storage" "Password for ${username}") || return
  content=$(read_input "Add SMB/CIFS Storage" "Content types (comma separated)" "backup,iso,vztmpl,snippets") || return
  nodes=$(read_input "Add SMB/CIFS Storage" "Nodes (optional, comma separated)") || return
  options=$(read_input "Add SMB/CIFS Storage" "Mount options (optional, e.g. vers=3.1.1,domain=WORKGROUP)") || return

  local cmd=(pvesm add cifs "$storage_id" --server "$server" --share "$share" --username "$username" --password "$password" --content "$content")
  [[ -n "$nodes" ]] && cmd+=(--nodes "$nodes")
  [[ -n "$options" ]] && cmd+=(--options "$options")

  if "${cmd[@]}" >/dev/null 2>&1; then
    msg_ok "SMB storage '${storage_id}' added"
  else
    msg_error "Failed to add SMB storage '${storage_id}'"
  fi

  pause
}

add_nfs_storage() {
  header_info
  local storage_id server export_path content nodes options

  storage_id=$(read_input "Add NFS Storage" "Storage ID (unique, e.g. nfs-vmdata)") || return
  server=$(read_input "Add NFS Storage" "NFS server/IP") || return
  export_path=$(read_input "Add NFS Storage" "Export path") || return
  content=$(read_input "Add NFS Storage" "Content types (comma separated)" "images,rootdir") || return
  nodes=$(read_input "Add NFS Storage" "Nodes (optional, comma separated)") || return
  options=$(read_input "Add NFS Storage" "Mount options (optional)") || return

  local cmd=(pvesm add nfs "$storage_id" --server "$server" --export "$export_path" --content "$content")
  [[ -n "$nodes" ]] && cmd+=(--nodes "$nodes")
  [[ -n "$options" ]] && cmd+=(--options "$options")

  if "${cmd[@]}" >/dev/null 2>&1; then
    msg_ok "NFS storage '${storage_id}' added"
  else
    msg_error "Failed to add NFS storage '${storage_id}'"
  fi

  pause
}

add_iscsi_storage() {
  header_info
  local storage_id portal target nodes

  storage_id=$(read_input "Add iSCSI Storage" "Storage ID (unique, e.g. iscsi-synology)") || return
  portal=$(read_input "Add iSCSI Storage" "Portal IP/FQDN") || return
  target=$(read_input "Add iSCSI Storage" "Target IQN (e.g. iqn.2000-01.com.synology:...)") || return
  nodes=$(read_input "Add iSCSI Storage" "Nodes (optional, comma separated)") || return

  local cmd=(pvesm add iscsi "$storage_id" --portal "$portal" --target "$target")
  [[ -n "$nodes" ]] && cmd+=(--nodes "$nodes")

  if "${cmd[@]}" >/dev/null 2>&1; then
    msg_ok "iSCSI storage '${storage_id}' added"
  else
    msg_error "Failed to add iSCSI storage '${storage_id}'"
  fi

  pause
}

add_lvm_on_base_storage() {
  header_info
  local storage_id base_storage vgname content shared

  storage_id=$(read_input "Add LVM Storage" "LVM Storage ID (unique, e.g. lvm-iscsi01)") || return
  base_storage=$(read_input "Add LVM Storage" "Base storage ID (usually iSCSI storage ID)") || return
  vgname=$(read_input "Add LVM Storage" "Volume Group name on target") || return
  content=$(read_input "Add LVM Storage" "Content types (comma separated)" "images,rootdir") || return
  shared=$(read_input "Add LVM Storage" "Shared across nodes? 1=yes, 0=no" "1") || return

  local cmd=(pvesm add lvm "$storage_id" --base "$base_storage" --vgname "$vgname" --content "$content" --shared "$shared")
  if "${cmd[@]}" >/dev/null 2>&1; then
    msg_ok "LVM storage '${storage_id}' added"
  else
    msg_error "Failed to add LVM storage '${storage_id}'"
  fi

  pause
}

remove_storage() {
  header_info
  local selection storage_id
  local -a results=()

  selection=$(pick_storages_multi "Remove Storage") || return
  if [[ -z "$selection" ]]; then
    msg_warn "No storage selected."
    pause
    return
  fi

  # Confirm each selected storage separately (defaults to No).
  for storage_id in $selection; do
    storage_id="${storage_id//\"/}"
    [[ -z "$storage_id" ]] && continue

    if confirm_danger "Remove Storage" \
      "Really remove storage '${storage_id}' from the Proxmox config?

This removes the storage definition only.
Data on the underlying share/target is NOT deleted."; then
      if pvesm remove "$storage_id" >/dev/null 2>&1; then
        results+=("removed  ${storage_id}")
      else
        results+=("FAILED   ${storage_id}")
      fi
    else
      results+=("skipped  ${storage_id}")
    fi
  done

  header_info
  echo -e "${BL}Remove storage — result${CL}\n"
  printf '  %s\n' "${results[@]}"
  echo
  pause
}

find_next_mp_slot() {
  local ctid="$1"
  local used

  used=$(pct config "$ctid" | awk -F: '/^mp[0-9]+:/ {gsub("mp", "", $1); print $1}')
  for i in $(seq 0 255); do
    if ! grep -qx "$i" <<<"$used"; then
      echo "$i"
      return
    fi
  done

  echo ""
}

add_lxc_mountpoint() {
  header_info
  local ctid host_path ct_path mp_slot

  ctid=$(pick_container "LXC: add mountpoint") || return
  host_path=$(read_input "LXC Mountpoint" "Host path (must exist, e.g. /mnt/pve/smb-media)") || return
  ct_path=$(read_input "LXC Mountpoint" "Container path (e.g. /mnt/media)") || return

  if [[ ! -d "$host_path" ]]; then
    msg_error "Host path does not exist: ${host_path}"
    pause
    return
  fi

  mp_slot=$(find_next_mp_slot "$ctid")
  if [[ -z "$mp_slot" ]]; then
    msg_error "No free mp slot available for container ${ctid}"
    pause
    return
  fi

  confirm_yes_no "LXC: add mountpoint" \
    "Add mp${mp_slot} to CT ${ctid}?

  ${host_path}  ->  ${ct_path}" 13 100 || return

  if pct set "$ctid" -mp"$mp_slot" "$host_path",mp="$ct_path" >/dev/null 2>&1; then
    msg_ok "Added mp${mp_slot}: ${host_path} -> ${ct_path} on CT ${ctid}"
    msg_warn "If CT is unprivileged, ensure UID/GID mapping and filesystem permissions fit your workload."
  else
    msg_error "Failed to add mountpoint to CT ${ctid}"
  fi

  pause
}

remove_lxc_mountpoint() {
  header_info
  local selection entry ctid mp_key mp_def
  local -a results=()

  selection=$(pick_all_mountpoints_multi "LXC: remove mountpoint") || return
  if [[ -z "$selection" ]]; then
    msg_warn "No mountpoint selected."
    pause
    return
  fi

  # Confirm each selected mountpoint separately (defaults to No).
  for entry in $selection; do
    entry="${entry//\"/}"
    [[ -z "$entry" ]] && continue
    ctid="${entry%%:*}"
    mp_key="${entry#*:}"
    mp_def=$(pct config "$ctid" | awk -F': ' -v k="$mp_key" '$1==k{print $2}')

    if confirm_danger "LXC: remove mountpoint" \
      "Remove ${mp_key} from CT ${ctid}?

  ${mp_key}: ${mp_def}

This only detaches the mountpoint from the container.
Data on the host is NOT deleted."; then
      if pct set "$ctid" -delete "$mp_key" >/dev/null 2>&1; then
        results+=("removed  CT ${ctid}  ${mp_key}")
      else
        results+=("FAILED   CT ${ctid}  ${mp_key}")
      fi
    else
      results+=("skipped  CT ${ctid}  ${mp_key}")
    fi
  done

  header_info
  echo -e "${BL}Remove mountpoint — result${CL}\n"
  printf '  %s\n' "${results[@]}"
  echo
  pause
}

list_lxc_mountpoints() {
  header_info
  local selection ctid mps

  selection=$(pick_containers_multi "LXC: list mountpoints") || return
  if [[ -z "$selection" ]]; then
    msg_warn "No container selected."
    pause
    return
  fi

  for ctid in $selection; do
    ctid="${ctid//\"/}"
    [[ -z "$ctid" ]] && continue
    echo -e "${BL}Mountpoints for CT ${ctid}${CL}"
    mps=$(pct config "$ctid" | awk '/^mp[0-9]+:/{print}')
    if [[ -n "$mps" ]]; then
      echo "$mps"
    else
      echo "  (no mountpoints configured)"
    fi
    echo
  done

  pause
}

host_create_samba_share() {
  header_info
  local share_name share_path user_name user_pass

  share_name=$(read_input "Host Samba Share" "Share name (e.g. data)") || return
  share_path=$(read_input "Host Samba Share" "Share path on host (e.g. /srv/samba/data)" "/srv/samba/${share_name}") || return
  user_name=$(read_input "Host Samba Share" "Linux/Samba username") || return
  user_pass=$(read_password "Host Samba Share" "Password for ${user_name}") || return

  msg_info "Installing Samba on host if needed"
  apt update >/dev/null 2>&1
  apt install -y samba >/dev/null 2>&1

  mkdir -p "$share_path"
  getent group sambashare >/dev/null 2>&1 || groupadd sambashare
  id "$user_name" >/dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -G sambashare "$user_name"
  usermod -aG sambashare "$user_name"
  chown -R root:sambashare "$share_path"
  chmod 2775 "$share_path"

  if ! (
    echo "$user_pass"
    echo "$user_pass"
  ) | smbpasswd -s -a "$user_name" >/dev/null 2>&1; then
    msg_error "Failed to set Samba password for ${user_name}"
    pause
    return
  fi

  if ! grep -q "^\[${share_name}\]" /etc/samba/smb.conf; then
    cat <<EOF >>/etc/samba/smb.conf

[${share_name}]
   comment = Proxmox Host Share (${share_name})
   path = ${share_path}
   browseable = yes
   read only = no
   guest ok = no
   create mask = 0664
   directory mask = 2775
   valid users = @sambashare
EOF
  fi

  testparm -s >/dev/null 2>&1 || {
    msg_error "Samba config validation failed (testparm). Check /etc/samba/smb.conf"
    pause
    return
  }

  systemctl enable --now smbd nmbd >/dev/null 2>&1
  systemctl restart smbd nmbd >/dev/null 2>&1

  msg_ok "Host SMB share created: //$(hostname -I | awk '{print $1}')/${share_name}"
  msg_warn "Best practice: prefer running Samba in a dedicated LXC/VM for cleaner host separation."

  pause
}

host_create_nfs_export() {
  header_info
  local export_path subnet options

  export_path=$(read_input "Host NFS Export" "Export path on host (e.g. /srv/proxmox-nfs)" "/srv/proxmox-nfs") || return
  subnet=$(read_input "Host NFS Export" "Allowed subnet/CIDR (e.g. 10.0.0.0/16)") || return
  options=$(read_input "Host NFS Export" "Export options" "rw,sync,no_subtree_check,no_root_squash") || return

  msg_info "Installing NFS server on host if needed"
  apt update >/dev/null 2>&1
  apt install -y nfs-kernel-server >/dev/null 2>&1

  mkdir -p "$export_path"
  chmod 0770 "$export_path"

  if ! grep -qE "^${export_path//\//\/}[[:space:]]+${subnet//\//\/}\(" /etc/exports; then
    echo "${export_path} ${subnet}(${options})" >>/etc/exports
  fi

  exportfs -ra >/dev/null 2>&1
  systemctl enable --now nfs-kernel-server >/dev/null 2>&1

  msg_ok "Host NFS export created: ${export_path} ${subnet}(${options})"
  msg_warn "Best practice: use host exports carefully; dedicated storage VM/LXC is often cleaner."
  pause
}

show_status() {
  header_info
  echo -e "${BL}pvesm status${CL}"
  pvesm status || true
  echo
  echo -e "${BL}Mounted /mnt/pve paths${CL}"
  mount | grep /mnt/pve || true
  echo
  echo -e "${BL}Mounted CIFS/NFS/iSCSI related paths${CL}"
  mount | grep -E ' type (cifs|nfs|nfs4)' || true
  echo
  echo -e "${BL}iSCSI sessions${CL}"
  iscsiadm -m session 2>/dev/null || true
  echo
  pause
}

main_menu() {
  while true; do
    local choice
    choice=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Share Allrounder" \
      --menu "Select action  (read-only actions are safe; write/remove actions ask for confirmation):" 30 116 22 \
      " " "──────────  READ-ONLY (safe, no changes)  ──────────" \
      "1" "Test   | SMB: manual mount test" \
      "2" "Test   | NFS: manual mount test" \
      "3" "Test   | iSCSI: discovery test" \
      "4" "Read   | LXC: list mountpoints" \
      "5" "Read   | Show storage/mount/iSCSI status" \
      "  " "──────────  WRITE (modifies config / host)  ──────────" \
      "6" "Write  | Proxmox: add SMB/CIFS storage" \
      "7" "Write  | Proxmox: add NFS storage" \
      "8" "Write  | Proxmox: add iSCSI storage" \
      "9" "Write  | Proxmox: add LVM on base storage (e.g. iSCSI)" \
      "10" "Write  | LXC: add bind mountpoint (pct set -mpX)" \
      "11" "Write  | Host: install Samba + create SMB share" \
      "12" "Write  | Host: install NFS server + create export" \
      "   " "──────────  REMOVE (destructive, defaults to No)  ──────────" \
      "13" "Remove | Proxmox: remove storage definition" \
      "14" "Remove | LXC: remove mountpoint (pct set -delete mpX)" \
      "0" "Exit" 3>&1 1>&2 2>&3) || break

    # '|| true' so a cancelled sub-dialog (whiptail returns non-zero) returns to the
    # menu instead of tripping 'set -e' and exiting the whole script.
    case "$choice" in
    1) manual_smb_test || true ;;
    2) manual_nfs_test || true ;;
    3) manual_iscsi_discovery || true ;;
    4) list_lxc_mountpoints || true ;;
    5) show_status || true ;;
    6) add_smb_storage || true ;;
    7) add_nfs_storage || true ;;
    8) add_iscsi_storage || true ;;
    9) add_lvm_on_base_storage || true ;;
    10) add_lxc_mountpoint || true ;;
    11) host_create_samba_share || true ;;
    12) host_create_nfs_export || true ;;
    13) remove_storage || true ;;
    14) remove_lxc_mountpoint || true ;;
    0) break ;;
    *) ;;
    esac
  done
}

header_info
root_check
pve_check
require_pve
ensure_packages
confirm_start || exit 0
main_menu

header_info
msg_ok "Finished."
