#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk
# Adapted from onethree7 (https://github.com/onethree7/proxmox-lxc-privilege-converter)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

if ! command -v curl >/dev/null 2>&1; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://git.community-scripts.org/community-scripts/ProxmoxVE/raw/branch/main/misc/core.func)
load_functions

set -euo pipefail
shopt -s inherit_errexit nullglob

APP="PVE-Privilege-Converter"
APP_TYPE="tools"
header_info "$APP"

check_root() {
  if [[ $EUID -ne 0 ]]; then
    msg_error "Script must be run as root"
    exit 1
  fi
}

select_target_storage_and_container_id() {
  echo -e "\nSelect target storage for restored container:\n"
  mapfile -t target_storages < <(pvesm status --content images | awk 'NR > 1 {print $1}')
  for i in "${!target_storages[@]}"; do
    printf "%s) %s\n" "$((i + 1))" "${target_storages[$i]}"
  done

  while true; do
    read -rp "Enter number of target storage: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#target_storages[@]})); then
      TARGET_STORAGE="${target_storages[$((choice - 1))]}"
      break
    else
      echo "Invalid selection. Try again."
    fi
  done

  next_free_id=$(pvesh get /cluster/nextid 2>/dev/null || echo 999)
  [[ "$next_free_id" =~ ^[0-9]+$ ]] || next_free_id=999

  echo ""
  read -rp "Suggested next free container ID: $next_free_id. Enter new container ID [default: $next_free_id]: " NEW_CONTAINER_ID
  NEW_CONTAINER_ID="${NEW_CONTAINER_ID:-$next_free_id}"
}

select_container() {
  mapfile -t lxc_list_raw < <(pct list | awk 'NR > 1 {print $1, $3}')
  lxc_list=()
  for entry in "${lxc_list_raw[@]}"; do
    [[ -n "$entry" ]] && lxc_list+=("$entry")
  done

  if [[ ${#lxc_list[@]} -eq 0 ]]; then
    msg_error "No containers found"
    exit 1
  fi

  PS3="Enter number of container to convert: "
  select opt in "${lxc_list[@]}"; do
    if [[ -n "$opt" ]]; then
      read -r CONTAINER_ID CONTAINER_NAME <<<"$opt"
      CONTAINER_NAME="${CONTAINER_NAME:-}"
      break
    else
      echo "Invalid selection. Try again."
    fi
  done
}

select_backup_storage() {
  echo -e "Select backup storage (temporary vzdump location):"
  mapfile -t backup_storages < <(pvesm status --content backup | awk 'NR > 1 {print $1}')
  local PS3="Enter number of backup storage: "

  select opt in "${backup_storages[@]}"; do
    if [[ -n "$opt" ]]; then
      BACKUP_STORAGE="$opt"
      break
    else
      echo "Invalid selection. Try again."
    fi
  done
}

backup_container() {
  msg_custom "📦" "\e[36m" "Backing up container $CONTAINER_ID"
  vzdump_output=$(mktemp)
  vzdump "$CONTAINER_ID" --compress zstd --storage "$BACKUP_STORAGE" --mode snapshot | tee "$vzdump_output"
  BACKUP_PATH=$(awk '/tar.zst/ {print $NF}' "$vzdump_output" | tr -d "'")
  if [ -z "$BACKUP_PATH" ] || ! grep -q "Backup job finished successfully" "$vzdump_output"; then
    rm "$vzdump_output"
    msg_error "Backup failed"
    exit 1
  fi
  rm "$vzdump_output"
  msg_ok "Backup complete: $BACKUP_PATH"
}

perform_conversion() {
  if pct config "$CONTAINER_ID" | grep -q 'unprivileged: 1'; then
    UNPRIVILEGED=true
  else
    UNPRIVILEGED=false
  fi

  msg_custom "🛠️" "\e[36m" "Restoring as $(if $UNPRIVILEGED; then echo privileged; else echo unprivileged; fi) container"
  restore_opts=("$NEW_CONTAINER_ID" "$BACKUP_PATH" --storage "$TARGET_STORAGE")
  if $UNPRIVILEGED; then
    restore_opts+=(--unprivileged false)
  else
    restore_opts+=(--unprivileged)
  fi

  if pct restore "${restore_opts[@]}" -ignore-unpack-errors 1; then
    msg_ok "Conversion successful"
  else
    msg_error "Conversion failed"
    exit 1
  fi
}

manage_states() {
  read -rp "Shutdown source and start new container? [Y/n]: " answer
  answer=${answer:-Y}
  if [[ $answer =~ ^[Yy] ]]; then
    pct shutdown "$CONTAINER_ID"
    for i in {1..36}; do
      sleep 5
      ! pct status "$CONTAINER_ID" | grep -q running && break
    done
    if pct status "$CONTAINER_ID" | grep -q running; then
      read -rp "Timeout reached. Force shutdown? [Y/n]: " force
      if [[ ${force:-Y} =~ ^[Yy] ]]; then
        pkill -9 -f "lxc-start -F -n $CONTAINER_ID"
      fi
    fi
    pct start "$NEW_CONTAINER_ID"
    msg_ok "New container started"
  else
    msg_custom "ℹ️" "\e[36m" "Skipped container state change"
  fi
}

cleanup_files() {
  read -rp "Delete backup archive? [$BACKUP_PATH] [Y/n]: " cleanup
  if [[ ${cleanup:-Y} =~ ^[Yy] ]]; then
    rm -f "$BACKUP_PATH" && msg_ok "Removed backup archive"
  else
    msg_custom "💾" "\e[36m" "Retained backup archive"
  fi
}

summary() {
  local conversion="Unknown"
  if [[ -n "${UNPRIVILEGED:-}" ]]; then
    if $UNPRIVILEGED; then
      conversion="Unprivileged → Privileged"
    else
      conversion="Privileged → Unprivileged"
    fi
  fi

  echo
  msg_custom "📄" "\e[36m" "Summary:"
  msg_custom "   " "\e[36m" "$(printf "%-22s %s" "Original Container:" "$CONTAINER_ID ($CONTAINER_NAME)")"
  msg_custom "   " "\e[36m" "$(printf "%-22s %s" "Backup Storage:" "$BACKUP_STORAGE")"
  msg_custom "   " "\e[36m" "$(printf "%-22s %s" "Target Storage:" "$TARGET_STORAGE")"
  msg_custom "   " "\e[36m" "$(printf "%-22s %s" "Backup Path:" "$BACKUP_PATH")"
  msg_custom "   " "\e[36m" "$(printf "%-22s %s" "New Container ID:" "$NEW_CONTAINER_ID")"
  msg_custom "   " "\e[36m" "$(printf "%-22s %s" "Privilege Conversion:" "$conversion")"
  echo
}

main() {
  header_info
  check_root
  select_container
  select_backup_storage
  backup_container
  select_target_storage_and_container_id
  perform_conversion
  manage_states
  cleanup_files
  summary
}

main
