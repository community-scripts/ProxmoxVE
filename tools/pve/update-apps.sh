#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: BvdBerg01 | Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "update-apps" "pve"

# =============================================================================
# CONFIGURATION VARIABLES
# Set these variables to skip interactive prompts (Whiptail dialogs)
# =============================================================================
# var_backup: Enable/disable backup before update
#   Options: "yes" | "no" | "" (empty = interactive prompt)
var_backup="${var_backup:-}"

# var_backup_storage: Storage location for backups (only used if var_backup=yes)
#   Options: Storage name from /etc/pve/storage.cfg (e.g., "local", "nas-backup")
#   Leave empty for interactive selection
var_backup_storage="${var_backup_storage:-}"

# var_container: Which containers to update
#   Options:
#     - "all"         : All containers with community-scripts tags
#     - "all_running" : Only running containers with community-scripts tags
#     - "all_stopped" : Only stopped containers with community-scripts tags
#     - "101,102,109" : Comma-separated list of specific container IDs
#     - ""            : Interactive selection via Whiptail
var_container="${var_container:-}"

# var_unattended: Run updates without user interaction inside containers
#   Options: "yes" | "no" | "" (empty = interactive prompt)
var_unattended="${var_unattended:-}"

# var_skip_confirm: Skip initial confirmation dialog
#   Options: "yes" | "no" (default: no)
var_skip_confirm="${var_skip_confirm:-no}"

# var_auto_reboot: Automatically reboot containers that require it after update
#   Options: "yes" | "no" | "" (empty = interactive prompt)
var_auto_reboot="${var_auto_reboot:-}"

# var_continue_on_error: Continue updating remaining containers if one update fails
#   Options: "yes" | "no" (default: no = stop on first error)
#   Note: containers with backups always attempt restore on failure regardless of this setting
var_continue_on_error="${var_continue_on_error:-no}"

# var_dry_run: Check for available updates without applying them
#   Options: "yes" | "no" (default: no)
#   Output: lists each container with current vs. latest version
#   Note: requires the container to be running; does not modify any container
var_dry_run="${var_dry_run:-no}"

# var_tags: Optionally override the tags used for auto-detection
#   Options: "community-script|proxmox-helper-scripts" (default)
var_tags="${var_tags:-community-script|proxmox-helper-scripts}"
# =============================================================================
# JSON CONFIG EXPORT
# Run with --export-config to output current configuration as JSON
# =============================================================================

function export_config_json() {
  cat <<EOF
{
  "var_backup": "${var_backup}",
  "var_backup_storage": "${var_backup_storage}",
  "var_container": "${var_container}",
  "var_unattended": "${var_unattended}",
  "var_skip_confirm": "${var_skip_confirm}",
  "var_auto_reboot": "${var_auto_reboot}",
  "var_continue_on_error": "${var_continue_on_error}",
  "var_dry_run": "${var_dry_run}",
  "var_tags": "${var_tags}"
}
EOF
}

function print_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Update LXC containers created with community-scripts.

Options:
  --help              Show this help message
  --export-config     Export current configuration as JSON

Environment Variables:
  var_backup          Enable backup before update (yes/no)
  var_backup_storage  Storage location for backups
  var_container       Container selection (all/all_running/all_stopped/101,102,...)
  var_unattended         Run updates unattended (yes/no)
  var_skip_confirm       Skip initial confirmation (yes/no)
  var_auto_reboot        Auto-reboot containers if required (yes/no)
  var_continue_on_error  Continue to next container on update failure (yes/no)
  var_dry_run            Check for updates without applying them (yes/no)
  var_tags               Optionally override auto-detection tags ("prod|smb|community-script")

Examples:
  # Run interactively
  $(basename "$0")

  # Update all running containers unattended with backup
  var_backup=yes var_backup_storage=local var_container=all_running var_unattended=yes var_skip_confirm=yes $(basename "$0")

  # Update specific containers without backup
  var_backup=no var_container=101,102,105 var_unattended=yes var_skip_confirm=yes $(basename "$0")

  # Unattended cron-style: skip confirm, continue on error, no backup
  var_backup=no var_container=all_running var_unattended=yes var_skip_confirm=yes var_continue_on_error=yes $(basename "$0")

  # Dry-run: show available updates for all running containers without applying
  var_container=all_running var_skip_confirm=yes var_dry_run=yes $(basename "$0")

  # Export current configuration
  $(basename "$0") --export-config
EOF
}

# Handle command line arguments
case "${1:-}" in
--help | -h)
  print_usage
  exit 0
  ;;
--export-config)
  export_config_json
  exit 0
  ;;
esac

# =============================================================================

function header_info {
  clear
  cat <<"EOF"
    __   _  ________   __  __          __      __
   / /  | |/ / ____/  / / / /___  ____/ /___ _/ /____
  / /   |   / /      / / / / __ \/ __  / __ `/ __/ _ \
 / /___/   / /___   / /_/ / /_/ / /_/ / /_/ / /_/  __/
/_____/_/|_\____/   \____/ .___/\__,_/\__,_/\__/\___/
                        /_/
EOF
}

function detect_service() {
  pushd $(mktemp -d) >/dev/null
  pct pull "$1" /usr/bin/update update 2>/dev/null
  service=$(cat update | sed 's|.*/ct/||g' | sed 's|\.sh).*||g')
  popd >/dev/null
}

function dry_run_container() {
  local container="$1"
  local service="$2"

  # Extract app name and source repo directly from check_for_gh_release call in the ct script
  # Pattern: check_for_gh_release "appname" "owner/repo"
  local check_line app_name app_lc source_repo
  check_line=$(echo "$script" | grep -m1 'check_for_gh_release')

  if [[ -z "$check_line" ]]; then
    echo -e "${YW}[DRY-RUN]${CL} Container $container ($service): no check_for_gh_release found — skipping"
    DRY_RUN_RESULT="no check_for_gh_release found — skipping"
    return
  fi

  app_name=$(echo "$check_line" | cut -d'"' -f2)
  source_repo=$(echo "$check_line" | cut -d'"' -f4)
  app_lc=$(echo "${app_name,,}" | tr -d ' ')

  if [[ -z "$source_repo" || "$source_repo" != *"/"* ]]; then
    echo -e "${YW}[DRY-RUN]${CL} Container $container ($service): cannot parse source repo — skipping"
    DRY_RUN_RESULT="cannot parse source repo — skipping"
    return
  fi

  # Read installed version from container (stored by check_for_gh_release as ~/.<appname>)
  local current_version
  current_version=$(pct exec "$container" -- bash -c "cat \$HOME/.${app_lc} 2>/dev/null" 2>/dev/null || true)
  current_version="${current_version#v}"

  # Query latest release from GitHub API
  local latest_version
  latest_version=$(curl -sSL --max-time 10 \
    -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "https://api.github.com/repos/${source_repo}/releases/latest" 2>/dev/null |
    grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/^v//')

  if [[ -z "$latest_version" ]]; then
    echo -e "${YW}[DRY-RUN]${CL} Container $container ($service): cannot fetch latest version from $source_repo"
    DRY_RUN_RESULT="cannot fetch latest version from $source_repo"
    return
  fi

  if [[ -z "$current_version" ]]; then
    echo -e "${BL}[DRY-RUN]${CL} Container $container ($service): installed version unknown, latest: ${latest_version} (${source_repo})"
    DRY_RUN_RESULT="version unknown — latest: ${latest_version}"
  elif [[ "$current_version" == "$latest_version" ]]; then
    echo -e "${GN}[DRY-RUN]${CL} Container $container ($service): up to date (${current_version})"
    DRY_RUN_RESULT="up to date (${current_version})"
  else
    echo -e "${YW}[DRY-RUN]${CL} Container $container ($service): update available ${current_version} → ${latest_version}"
    DRY_RUN_RESULT="update available ${current_version} → ${latest_version}"
  fi
}

function backup_container() {
  msg_info "Creating backup for container $1"
  vzdump $1 --compress zstd --storage $STORAGE_CHOICE -notes-template "{{guestname}} - community-scripts backup updater" >/dev/null 2>&1
  status=$?

  if [ $status -eq 0 ]; then
    msg_ok "Backup created"
  else
    msg_error "Backup failed for container $1"
    exit 235
  fi
}

function get_backup_storages() {
  STORAGES=$(awk '
/^[a-z]+:/ {
    if (name != "") {
        if (has_backup || (!has_content && type == "dir")) print name
    }
    split($0, a, ":")
    type = a[1]
    name = a[2]
    gsub(/^[ \t]+|[ \t]+$/, "", name)
    has_content = 0
    has_backup = 0
}
/^[ \t]*content/ {
    has_content = 1
    if ($0 ~ /backup/) has_backup = 1
}
END {
    if (name != "") {
        if (has_backup || (!has_content && type == "dir")) print name
    }
}
' /etc/pve/storage.cfg)
}

# Structured result tracking for the final summary report
# Each entry: "CTID|service|STATUS|details"
declare -a UPDATE_RESULTS=()
function log_result() {
  # log_result <ctid> <service> <STATUS> <details>
  UPDATE_RESULTS+=("${1}|${2}|${3}|${4}")
}

header_info

# =============================================================================
# LOGGING SETUP
# Key events are written directly to a timestamped log file under
# /usr/local/community-scripts/update_apps/ — this avoids any stdout
# redirection that would break interactive spinners or whiptail dialogs.
# The full summary table is appended at the end of the run.
# =============================================================================
LOG_DIR="/usr/local/community-scripts/update_apps"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/$(date '+%Y%m%d_%H%M%S').log"
echo "Update started: $(date '+%Y-%m-%d %H:%M:%S')" >"$LOG_FILE"

function log_write() {
  echo "[$(date '+%H:%M:%S')] $*" >>"$LOG_FILE"
}

# Skip confirmation if var_skip_confirm is set to yes
if [[ "$var_skip_confirm" != "yes" ]]; then
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "LXC App Update" --yesno "This will update apps in LXCs installed by Helper-Scripts. Proceed?" 10 58 || exit
fi

tags_formatted="${var_tags//|/, }"
msg_info "Loading all possible LXC containers from Proxmox VE with tags: ${tags_formatted}. This may take a few seconds..."
NODE=$(hostname)
containers=$(pct list | tail -n +2 | awk '{print $0 " " $4}')

if [ -z "$containers" ]; then
  whiptail --title "LXC Container Update" --msgbox "No LXC containers available!" 10 60
  exit 234
fi

menu_items=()
FORMAT="%-10s %-15s %-10s"
TAGS="${var_tags:-community-script|proxmox-helper-scripts}"

while read -r container; do
  container_id=$(echo $container | awk '{print $1}')
  container_name=$(echo $container | awk '{print $2}')
  container_status=$(echo $container | awk '{print $3}')
  formatted_line=$(printf "$FORMAT" "$container_name" "$container_status")
  if pct config "$container_id" | grep -qE "[^-][; ](${TAGS}).*"; then
    menu_items+=("$container_id" "$formatted_line" "OFF")
  fi
done <<<"$containers"
msg_ok "Loaded $((${#menu_items[@]} / 3)) containers"

# Determine container selection based on var_container
if [[ -n "$var_container" ]]; then
  case "$var_container" in
  all)
    # Select all containers with matching tags
    CHOICE=""
    for ((i = 0; i < ${#menu_items[@]}; i += 3)); do
      CHOICE="$CHOICE ${menu_items[$i]}"
    done
    CHOICE=$(echo "$CHOICE" | xargs)
    ;;
  all_running)
    # Select only running containers with matching tags
    CHOICE=""
    for ((i = 0; i < ${#menu_items[@]}; i += 3)); do
      cid="${menu_items[$i]}"
      if pct status "$cid" 2>/dev/null | grep -q "running"; then
        CHOICE="$CHOICE $cid"
      fi
    done
    CHOICE=$(echo "$CHOICE" | xargs)
    ;;
  all_stopped)
    # Select only stopped containers with matching tags
    CHOICE=""
    for ((i = 0; i < ${#menu_items[@]}; i += 3)); do
      cid="${menu_items[$i]}"
      if pct status "$cid" 2>/dev/null | grep -q "stopped"; then
        CHOICE="$CHOICE $cid"
      fi
    done
    CHOICE=$(echo "$CHOICE" | xargs)
    ;;
  *)
    # Assume comma-separated list of container IDs
    CHOICE=$(echo "$var_container" | tr ',' ' ')
    ;;
  esac

  if [[ -z "$CHOICE" ]]; then
    msg_error "No containers matched the selection criteria: $var_container ${var_tags:-community-script|proxmox-helper-scripts}"
    exit 234
  fi
  msg_ok "Selected containers: $CHOICE"
else
  CHOICE=$(whiptail --title "LXC Container Update" \
    --checklist "Select LXC containers to update:" 25 60 13 \
    "${menu_items[@]}" 3>&2 2>&1 1>&3 | tr -d '"')

  if [ -z "$CHOICE" ]; then
    whiptail --title "LXC Container Update" \
      --msgbox "No containers selected!" 10 60
    exit 0
  fi
fi

header_info

# Determine backup choice based on var_backup
# Dry-run never needs a backup — skip the prompt entirely
if [[ "$var_dry_run" == "yes" ]]; then
  BACKUP_CHOICE="no"
elif [[ -n "$var_backup" ]]; then
  BACKUP_CHOICE="$var_backup"
else
  BACKUP_CHOICE="no"
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "LXC Container Update" --yesno "Do you want to backup your containers before update?" 10 58); then
    BACKUP_CHOICE="yes"
  fi
fi

# Determine unattended update based on var_unattended
# Dry-run never executes updates — skip the prompt entirely
if [[ "$var_dry_run" == "yes" ]]; then
  UNATTENDED_UPDATE="no"
elif [[ -n "$var_unattended" ]]; then
  UNATTENDED_UPDATE="$var_unattended"
else
  UNATTENDED_UPDATE="no"
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "LXC Container Update" --yesno "Run updates unattended?" 10 58); then
    UNATTENDED_UPDATE="yes"
  fi
fi

if [ "$BACKUP_CHOICE" == "yes" ]; then
  get_backup_storages

  if [ -z "$STORAGES" ]; then
    msg_error "No storage with 'backup' support found!"
    exit 119
  fi

  # Determine storage based on var_backup_storage
  if [[ -n "$var_backup_storage" ]]; then
    # Validate that the specified storage exists and supports backups
    if echo "$STORAGES" | grep -qw "$var_backup_storage"; then
      STORAGE_CHOICE="$var_backup_storage"
      msg_ok "Using backup storage: $STORAGE_CHOICE"
    else
      msg_error "Specified backup storage '$var_backup_storage' not found or doesn't support backups!"
      msg_info "Available storages: $(echo $STORAGES | tr '\n' ' ')"
      exit 119
    fi
  else
    MENU_ITEMS=()
    for STORAGE in $STORAGES; do
      MENU_ITEMS+=("$STORAGE" "")
    done

    STORAGE_CHOICE=$(whiptail --title "Select storage device" --menu "Select a storage device (Only storage devices with 'backup' support are listed):" 15 50 5 "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$STORAGE_CHOICE" ]; then
      msg_error "No storage selected!"
      exit 0
    fi
  fi
fi

UPDATE_CMD="update;"
if [ "$UNATTENDED_UPDATE" == "yes" ]; then
  UPDATE_CMD="export PHS_SILENT=1;update;"
fi

containers_needing_reboot=()
for container in $CHOICE; do
  echo -e "${BL}[INFO]${CL} Updating container $container"
  log_write "Container $container: starting"

  if [ "$BACKUP_CHOICE" == "yes" ]; then
    backup_container $container
  fi

  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  status=$(pct status $container)
  template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
  if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
    echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
    pct start $container
    echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
    sleep 5
  fi

  #1) Detect service using the service name in the update command
  detect_service $container

  #1.1) If update script not detected, return
  if [ -z "${service}" ]; then
    echo -e "${YW}[WARN]${CL} Update script not found. Skipping to next container"
    log_result "$container" "(unknown)" "SKIPPED" "No update script found in container"
    log_write "Container $container: SKIPPED — no update script found"
    continue
  else
    echo -e "${BL}[INFO]${CL} Detected service: ${GN}${service}${CL}"
    log_write "Container $container: detected service '$service'"
  fi

  #2) Extract service build/update resource requirements from config/installation file
  script=$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${service}.sh)

  #2.1) Check if the script downloaded successfully
  if [ $? -ne 0 ]; then
    echo -e "${RD}[ERROR]${CL} Issue while downloading install script."
    echo -e "${YW}[WARN]${CL} Unable to assess build resource requirements. Proceeding with current resources."
  fi

  config=$(pct config "$container")
  build_cpu=$(echo "$script" | { grep -m 1 "var_cpu" || test $? = 1; } | sed 's|.*=||g' | sed 's|"||g' | sed 's|.*var_cpu:-||g' | sed 's|}||g')
  build_ram=$(echo "$script" | { grep -m 1 "var_ram" || test $? = 1; } | sed 's|.*=||g' | sed 's|"||g' | sed 's|.*var_ram:-||g' | sed 's|}||g')
  run_cpu=$(echo "$script" | { grep -m 1 "pct set \$CTID -cores" || test $? = 1; } | sed 's|.*cores ||g')
  run_ram=$(echo "$script" | { grep -m 1 "pct set \$CTID -memory" || test $? = 1; } | sed 's|.*memory ||g')
  current_cpu=$(echo "$config" | grep -m 1 "cores:" | sed 's|cores: ||g')
  current_ram=$(echo "$config" | grep -m 1 "memory:" | sed 's|memory: ||g')

  #Test if all values are valid (>0)
  if [ -z "${run_cpu}" ] || [ "$run_cpu" -le 0 ]; then
    #echo "No valid value found for run_cpu. Assuming same as current configuration."
    run_cpu=$current_cpu
  fi

  if [ -z "${run_ram}" ] || [ "$run_ram" -le 0 ]; then
    #echo "No valid value found for run_ram. Assuming same as current configuration."
    run_ram=$current_ram
  fi

  if [ -z "${build_cpu}" ] || [ "$build_cpu" -le 0 ]; then
    #echo "No valid value found for build_cpu. Assuming same as current configuration."
    build_cpu=$current_cpu
  fi

  if [ -z "${build_ram}" ] || [ "$build_ram" -le 0 ]; then
    #echo "No valid value found for build_ram. Assuming same as current configuration."
    build_ram=$current_ram
  fi

  UPDATE_BUILD_RESOURCES=0
  if [ "$build_cpu" -gt "$run_cpu" ] || [ "$build_ram" -gt "$run_ram" ]; then
    UPDATE_BUILD_RESOURCES=1
  fi

  #3) if build resources are different than run resources, then:
  if [ "$UPDATE_BUILD_RESOURCES" -eq "1" ] && [[ "$var_dry_run" != "yes" ]]; then
    pct set "$container" --cores "$build_cpu" --memory "$build_ram"
  fi

  #3.5) Dry-run: report update availability without applying
  if [[ "$var_dry_run" == "yes" ]]; then
    DRY_RUN_RESULT=""
    dry_run_container "$container" "$service"
    log_result "$container" "$service" "DRY-RUN" "${DRY_RUN_RESULT:-version check only}"
    log_write "Container $container ($service): DRY-RUN — ${DRY_RUN_RESULT:-version check only}"
    continue
  fi

  #4) Update service, using the update command
  # Prepend a no-op 'clear' wrapper to PATH so update scripts calling clear
  # don't fail without a TTY — works for all shells incl. ash (no export -f)
  SETUP_CMD="mkdir -p /tmp/.nc; printf '#!/bin/sh\n:\n' > /tmp/.nc/clear; chmod +x /tmp/.nc/clear; export PATH=/tmp/.nc:\$PATH; export TERM=dumb; "
  case "$os" in
  alpine) pct exec "$container" -- ash -c "${SETUP_CMD}${UPDATE_CMD}" ;;
  archlinux) pct exec "$container" -- bash -c "${SETUP_CMD}${UPDATE_CMD}" ;;
  fedora | rocky | centos | alma) pct exec "$container" -- bash -c "${SETUP_CMD}${UPDATE_CMD}" ;;
  ubuntu | debian | devuan) pct exec "$container" -- bash -c "${SETUP_CMD}${UPDATE_CMD}" ;;
  opensuse) pct exec "$container" -- bash -c "${SETUP_CMD}${UPDATE_CMD}" ;;
  esac
  exit_code=$?

  #5) if build resources are different than run resources, then:
  if [ "$UPDATE_BUILD_RESOURCES" -eq "1" ]; then
    pct set "$container" --cores "$run_cpu" --memory "$run_ram"
  fi

  if pct exec "$container" -- [ -e "/var/run/reboot-required" ]; then
    # Get the container's hostname and add it to the list
    container_hostname=$(pct exec "$container" hostname)
    containers_needing_reboot+=("$container ($container_hostname)")
  fi

  if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
    echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
    pct shutdown $container &>/dev/null &
  fi

  if [ $exit_code -eq 0 ]; then
    msg_ok "Updated container $container"
    log_result "$container" "$service" "OK" "Updated successfully"
    log_write "Container $container ($service): OK"
  elif [ $exit_code -eq 75 ]; then
    echo -e "${YW}[WARN]${CL} Container $container skipped (requires interactive mode)"
    log_result "$container" "$service" "SKIPPED" "Requires interactive mode (exit 75)"
    log_write "Container $container ($service): SKIPPED — requires interactive mode"
  elif [ $exit_code -eq 113 ]; then
    echo -e "${YW}[WARN]${CL} Container $container skipped (under-provisioned: increase CPU/RAM to match template)"
    log_result "$container" "$service" "SKIPPED" "Under-provisioned — increase CPU/RAM to match template"
    log_write "Container $container ($service): SKIPPED — under-provisioned"
  elif [ $exit_code -eq 114 ]; then
    echo -e "${YW}[WARN]${CL} Container $container skipped (storage critically low on /boot)"
    log_result "$container" "$service" "SKIPPED" "Storage critically low on /boot (>80%)"
    log_write "Container $container ($service): SKIPPED — storage critically low on /boot"
  elif [ "$BACKUP_CHOICE" == "yes" ]; then
    msg_error "Update failed for container $container (exit code: $exit_code) — attempting restore"
    log_write "Container $container ($service): FAILED (exit $exit_code) — attempting restore"
    msg_info "Restoring LXC $container from backup ($STORAGE_CHOICE)"
    pct stop $container
    LXC_STORAGE=$(pct config $container | awk -F '[:,]' '/rootfs/ {print $2}')
    BACKUP_ENTRY=$(pvesm list "$STORAGE_CHOICE" 2>/dev/null | awk -v ctid="$container" '$1 ~ "vzdump-lxc-"ctid"-" || $1 ~ "/ct/"ctid"/" {print $1}' | sort -r | head -n1)
    if [ -z "$BACKUP_ENTRY" ]; then
      msg_error "No backup found in storage $STORAGE_CHOICE for container $container"
      log_result "$container" "$service" "FAILED" "Update failed (exit $exit_code) — no backup found for restore"
      log_write "Container $container ($service): FAILED — no backup found for restore"
      exit 235
    fi
    msg_info "Restoring from: $BACKUP_ENTRY"
    pct restore $container "$BACKUP_ENTRY" --storage $LXC_STORAGE --force >/dev/null 2>&1
    restorestatus=$?
    if [ $restorestatus -eq 0 ]; then
      pct start $container
      msg_ok "Container $container successfully restored from backup"
      log_result "$container" "$service" "RESTORED" "Update failed (exit $exit_code) — restored from backup"
      log_write "Container $container ($service): RESTORED from $BACKUP_ENTRY"
    else
      msg_error "Restore failed for container $container"
      log_result "$container" "$service" "FAILED" "Update failed (exit $exit_code) — restore also failed"
      log_write "Container $container ($service): FAILED — restore also failed"
      exit 235
    fi
  else
    msg_error "Update failed for container $container (exit code: $exit_code)"
    log_result "$container" "$service" "FAILED" "Exit code $exit_code"
    log_write "Container $container ($service): FAILED (exit $exit_code)"
    if [[ "$var_continue_on_error" == "yes" ]]; then
      echo -e "${YW}[WARN]${CL} Continuing to next container (var_continue_on_error=yes)"
      continue
    else
      exit "$exit_code"
    fi
  fi
done

wait
header_info
if [[ "$var_dry_run" == "yes" ]]; then
  echo -e "${GN}Dry-run complete. No containers were modified.${CL}\n"
else
  echo -e "${GN}The process is complete, and the containers have been successfully updated.${CL}\n"
fi

# =============================================================================
# SUMMARY REPORT
# =============================================================================
if [ "${#UPDATE_RESULTS[@]}" -gt 0 ]; then
  SEPARATOR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  HEADER=$(printf "  %-8s  %-22s  %-10s  %s" "CTID" "Service" "Status" "Details")

  # terminal output (with colours)
  echo ""
  echo "$SEPARATOR"
  echo "$HEADER"
  echo "$SEPARATOR"
  for entry in "${UPDATE_RESULTS[@]}"; do
    IFS='|' read -r _ctid _svc _status _details <<<"$entry"
    case "$_status" in
    OK) _color="${GN}" ;;
    FAILED) _color="${RD}" ;;
    RESTORED) _color="${YW}" ;;
    *) _color="${YW}" ;;
    esac
    printf "  %-8s  %-22s  ${_color}%-10s${CL}  %s\n" "$_ctid" "$_svc" "$_status" "$_details"
  done
  echo "$SEPARATOR"
  echo ""
  echo "Full log: $LOG_FILE"
  echo ""

  # append plain-text summary to log file
  {
    echo ""
    echo "Update finished: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "$SEPARATOR"
    echo "$HEADER"
    echo "$SEPARATOR"
    for entry in "${UPDATE_RESULTS[@]}"; do
      IFS='|' read -r _ctid _svc _status _details <<<"$entry"
      printf "  %-8s  %-22s  %-10s  %s\n" "$_ctid" "$_svc" "$_status" "$_details"
    done
    echo "$SEPARATOR"
  } >>"$LOG_FILE"
fi
if [ "${#containers_needing_reboot[@]}" -gt 0 ]; then
  echo -e "${RD}The following containers require a reboot:${CL}"
  for container_name in "${containers_needing_reboot[@]}"; do
    echo "$container_name"
  done

  # Determine reboot choice based on var_auto_reboot
  REBOOT_CHOICE="no"
  if [[ -n "$var_auto_reboot" ]]; then
    REBOOT_CHOICE="$var_auto_reboot"
  else
    echo -ne "${INFO} Do you wish to reboot these containers? <yes/No>  "
    read -r prompt
    if [[ ${prompt,,} =~ ^(yes)$ ]]; then
      REBOOT_CHOICE="yes"
    fi
  fi

  if [[ "$REBOOT_CHOICE" == "yes" ]]; then
    echo -e "${CROSS}${HOLD} ${YWB}Rebooting containers.${CL}"
    for container_name in "${containers_needing_reboot[@]}"; do
      container=$(echo $container_name | cut -d " " -f 1)
      pct reboot ${container}
    done
  fi
fi
