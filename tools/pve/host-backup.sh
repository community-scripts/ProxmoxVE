#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck / community-scripts style extended by OpenAI and ClaudeAI
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]:-$0}")"

CONFIG_DIR="/etc/pve-host-backup"
CONFIG_FILE="$CONFIG_DIR/config.conf"
LOG_DIR="/var/log/pve-host-backup"
LOG_FILE="$LOG_DIR/backup.log"
CRON_TAG="# PVE_HOST_BACKUP_MANAGED"
DEFAULT_BACKUP_PATH="/root"
DEFAULT_WORK_DIR="/etc/"
VIRTUAL_ROOT_CRONTAB="__ROOT_CRONTAB_EXPORT__"
VIRTUAL_PMXCFS_SQL_DUMP="__PMXCFS_SQL_DUMP__"
ALL_MARKER_PREFIX="__ALL__:"
SCRIPT_VERSION="1.0.0"
UPSTREAM_SCRIPT_PAGE_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/tools/pve/host-backup.sh"
DEFAULT_CRON_LOCAL_SCRIPT_PATH="/usr/local/sbin/pve-host-backup.sh"
UI_H="22"
UI_W="110"
UI_MENU_H="10"

[[ $EUID -eq 0 ]] || { echo "Please run as root."; exit 1; }
command -v tar      >/dev/null 2>&1 || { echo "tar is required.";          exit 1; }
command -v whiptail >/dev/null 2>&1 || { echo "whiptail is required.";     exit 1; }
command -v crontab  >/dev/null 2>&1 || { echo "cron/crontab is required."; exit 1; }

# Telemetry (non-fatal – silently ignored if unreachable)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "host-backup" "pve"

TMP_DIR=""
cleanup() { [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# Detect whether we have an interactive terminal (false when run from cron)
[[ -t 1 ]] && HAS_TTY=true || HAS_TTY=false

ts()           { date '+%Y-%m-%d %H:%M:%S'; }
log()          { mkdir -p "$LOG_DIR"; echo "[$(ts)] $*" >> "$LOG_FILE"; }
trim_quotes()  { local s="$1"; s="${s%\"}"; s="${s#\"}"; printf '%s' "$s"; }
escape_squote(){ printf "%s" "$1" | sed "s/'/'\\''/g"; }

normalize_backup_path() {
  local path="${1:-$DEFAULT_BACKUP_PATH}"
  while [[ "$path" != "/" && "$path" == */ ]]; do path="${path%/}"; done
  printf '%s' "$path"
}

download_script_to_local() {
  mkdir -p "$(dirname "$2")" || return 1
  curl -fsSL "$1" -o "$2"   || return 1
  chmod +x "$2"
}

# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------
header_info() {
  clear
  cat <<"EOF"
   __ __         __    ___           __
  / // /__  ___ / /_  / _ )___ _____/ /____ _____
 / _  / _ \(_-</ __/ / _  / _ `/ __/  '_/ // / _ \
/_//_/\___/___/\__/ /____/\_,_/\__/_/\_\\_,_/ .__/
                                           /_/
EOF
  echo
  echo "Proxmox VE Host Backup v$SCRIPT_VERSION"
  echo
}

msg_box()  { if $HAS_TTY; then whiptail --backtitle "Proxmox VE Helper Scripts" --title "$1" --msgbox "$2" "$UI_H" "$UI_W"; else log "MSG[$1]: $2"; fi; }
yes_no()   { whiptail --backtitle "Proxmox VE Helper Scripts" --title "$1" --yesno    "$2" "$UI_H" "$UI_W"; }
input_box(){ whiptail --backtitle "Proxmox VE Helper Scripts" --title "$1" --inputbox "$2" "$UI_H" "$UI_W" "$3" 3>&1 1>&2 2>&3; }

# ---------------------------------------------------------------------------
# Config load / save
# ---------------------------------------------------------------------------
load_config() {
  [[ -f "$CONFIG_FILE" ]] || return 1
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
}

save_config() {
  local backup_path="$1" work_dir="$2" compression="$3"
  local retention_days="$4" include_log_in_archive="$5" copy_log_to_backup_path="$6"
  shift 6

  local list="" item
  for item in "$@"; do
    item="$(trim_quotes "$item")"
    [[ -z "$item" ]] && continue
    list+="'$(escape_squote "$item")' "
  done

  mkdir -p "$CONFIG_DIR"
  umask 077
  cat > "$CONFIG_FILE" <<EOF
BACKUP_PATH='$(escape_squote "$backup_path")'
WORK_DIR='$(escape_squote "$work_dir")'
COMPRESSION='$(escape_squote "$compression")'
RETENTION_DAYS='$(escape_squote "$retention_days")'
INCLUDE_LOG_IN_ARCHIVE='$(escape_squote "$include_log_in_archive")'
COPY_LOG_TO_BACKUP_PATH='$(escape_squote "$copy_log_to_backup_path")'
SELECTED_ITEMS=($list)
EOF
  log "Saved config to $CONFIG_FILE"
}

# ---------------------------------------------------------------------------
# Item selection helpers
# ---------------------------------------------------------------------------
select_items_interactive() {
  local work_dir="$1"
  local -n selected_ref=$2
  local menu=("ALL" "Backup everything directly inside $work_dir" "OFF")
  local found=0 path name

  shopt -s nullglob dotglob
  for path in "$work_dir"*; do
    [[ -e "$path" ]] || continue
    name="$(basename "$path")"
    menu+=("$name" "$path" "OFF")
    found=1
  done
  shopt -u nullglob dotglob

  if [[ $found -eq 0 ]]; then
    msg_box "No Items Found" "No files or folders were found in:\n\n$work_dir"
    return 1
  fi

  local choice
  choice=$(whiptail --backtitle "Proxmox VE Host Backup" \
    --title "Working in the ${work_dir} directory" \
    --checklist "\nSelect what files/directories to backup:" "$UI_H" "$UI_W" 12 \
    "${menu[@]}" 3>&1 1>&2 2>&3) || return 1

  selected_ref=()
  local token
  for token in $choice; do
    token="$(trim_quotes "$token")"
    if [[ "$token" == "ALL" ]]; then
      selected_ref+=("${ALL_MARKER_PREFIX}${work_dir}")
      break
    else
      selected_ref+=("${work_dir}${token}")
    fi
  done

  if [[ ${#selected_ref[@]} -eq 0 ]]; then
    msg_box "Nothing Selected" "Please select at least one file or directory."
    return 1
  fi
}

select_recommended_extras() {
  local -n extras_ref=$1
  local etc_default="${2:-OFF}" root_default="${3:-OFF}"
  local usrlocal_default="${4:-OFF}" opt_default="${5:-OFF}" cronspool_default="${6:-OFF}"

  local choice
  choice=$(whiptail --backtitle "Proxmox VE Host Backup" \
    --title "Recommended extra paths" \
    --checklist "Optional recommended extras for Proxmox host backups.\n\nOnly keep what you actually want." \
    "$UI_H" "$UI_W" 12 \
    "/etc/"                          "Best default for most host config"             "$etc_default" \
    "/root/"                         "SSH keys, scripts, notes, custom files"        "$root_default" \
    "/usr/local/"                    "Custom local tools or scripts"                 "$usrlocal_default" \
    "/opt/"                          "Custom applications"                           "$opt_default" \
    "/var/spool/cron/"               "Cron jobs (if you use cron heavily)"           "$cronspool_default" \
    "$VIRTUAL_ROOT_CRONTAB"          "Export root crontab to a file and include it"  "OFF" \
    "/var/lib/pve-cluster/config.db" "Raw pmxcfs backend database"                   "OFF" \
    "$VIRTUAL_PMXCFS_SQL_DUMP"       "Safer pmxcfs SQL dump of /etc/pve backend"     "OFF" \
    3>&1 1>&2 2>&3) || return 0

  extras_ref=()
  local token
  for token in $choice; do extras_ref+=("$(trim_quotes "$token")"); done
}

parse_csv_paths() {
  local -n out_ref=$2
  out_ref=()
  local token
  for token in ${1//,/ }; do
    token="${token// /}"
    [[ -n "$token" ]] || continue
    [[ "$token" == */ ]] || token="$token/"
    out_ref+=("$token")
  done
}

dedupe_items() {
  local -n in_ref=$1
  local -n out_ref=$2
  out_ref=()
  local -A seen=() all_dirs=()
  local item

  # First pass: record every directory covered by an ALL marker.
  for item in "${in_ref[@]}"; do
    [[ "$item" == ${ALL_MARKER_PREFIX}* ]] && all_dirs["${item#${ALL_MARKER_PREFIX}}"]="1"
  done

  # Second pass: drop duplicates and plain paths subsumed by an ALL marker.
  for item in "${in_ref[@]}"; do
    [[ -n "$item" ]] || continue
    if [[ "$item" != ${ALL_MARKER_PREFIX}* ]]; then
      local candidate="${item%/}/"
      [[ -n "${all_dirs[$candidate]:-}" ]] && continue
    fi
    if [[ -z "${seen[$item]:-}" ]]; then
      out_ref+=("$item")
      seen[$item]=1
    fi
  done
}

# ---------------------------------------------------------------------------
# Backup execution
# ---------------------------------------------------------------------------

# Expands ALL markers, resolves virtual items (crontab/sql dump), checks paths exist.
collect_backup_items() {
  local -n in_ref=$1
  local -n out_ref=$2
  out_ref=()
  TMP_DIR="$(mktemp -d /tmp/pve-host-backup.XXXXXX)"

  local item dir p export_file dump_file
  for item in "${in_ref[@]}"; do
    if [[ "$item" == ${ALL_MARKER_PREFIX}* ]]; then
      dir="${item#${ALL_MARKER_PREFIX}}"
      shopt -s nullglob dotglob
      for p in "$dir"*; do [[ -e "$p" ]] && out_ref+=("$p"); done
      shopt -u nullglob dotglob
    elif [[ "$item" == "$VIRTUAL_ROOT_CRONTAB" ]]; then
      export_file="$TMP_DIR/root-crontab.txt"
      crontab -l > "$export_file" 2>/dev/null || true
      out_ref+=("$export_file")
    elif [[ "$item" == "$VIRTUAL_PMXCFS_SQL_DUMP" ]]; then
      if command -v sqlite3 >/dev/null 2>&1 && [[ -f /var/lib/pve-cluster/config.db ]]; then
        dump_file="$TMP_DIR/pve-cluster-config.sql"
        sqlite3 /var/lib/pve-cluster/config.db .dump > "$dump_file"
        out_ref+=("$dump_file")
      else
        log "Skipped pmxcfs SQL dump: sqlite3 missing or config.db not found"
      fi
    elif [[ -e "$item" ]]; then
      out_ref+=("$item")
    else
      log "Skipped missing path: $item"
    fi
  done
}

build_summary_text() {
  local backup_path="$1" work_dir="$2" compression="$3"
  local retention_days="$4" include_log_in_archive="$5" copy_log_to_backup_path="$6"
  shift 6

  local summary="Backup target:           $backup_path
Primary directory:       $work_dir
Compression:             $compression
Retention:               ${retention_days:-0} days
Include log in archive:  $include_log_in_archive
Copy log next to backup: $copy_log_to_backup_path

Selected items:"
  local item
  for item in "$@"; do
    case "$item" in
      "$VIRTUAL_ROOT_CRONTAB")    summary+="\n - Export root crontab" ;;
      "$VIRTUAL_PMXCFS_SQL_DUMP") summary+="\n - Generate pmxcfs SQL dump" ;;
      ${ALL_MARKER_PREFIX}*)      summary+="\n - ${item#${ALL_MARKER_PREFIX}} -> ALL" ;;
      *)                          summary+="\n - $item" ;;
    esac
  done
  printf '%s' "$summary"
}

# Compute whiptail height from content: count real lines + border padding, capped at terminal height.
summary_height() {
  local text="$1"
  local lines; lines=$(printf '%b' "$text" | wc -l)
  local h=$(( lines + 8 ))
  [[ $h -lt $UI_H ]] && h=$UI_H
  [[ $h -gt 50 ]] && h=50
  printf '%s' "$h"
}

show_selected_summary() {
  local text; text="$(build_summary_text "$@")"
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Backup Summary"     --msgbox "$text" "$(summary_height "$text")" "$UI_W"
}

confirm_run_with_summary() {
  local text; text="Run backup with these saved settings?

Choose No to review/change them first.

$(build_summary_text "$@")"
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Run Saved Settings"     --yesno "$text" "$(summary_height "$text")" "$UI_W"
}

perform_backup() {
  local backup_path="$1" work_dir="$2" compression="$3"
  local retention_days="$4" include_log_in_archive="$5" copy_log_to_backup_path="$6"
  shift 6
  local selected=("$@")

  backup_path="$(normalize_backup_path "$backup_path")"

  # Verify backup path is writable
  if ! mkdir -p "$backup_path" 2>/dev/null; then
    msg_box "Backup Path Error" "Unable to create or access backup path:\n\n$backup_path"
    return 1
  fi
  local testfile="$backup_path/.pve-host-backup-write-test.$$"
  if ! : > "$testfile" 2>/dev/null; then
    msg_box "Backup Path Error" \
      "Backup path is not writable/reachable:\n\n$backup_path\n\n(For network shares, verify mount/connectivity.)"
    return 1
  fi
  rm -f "$testfile"

  local prepared=()
  collect_backup_items selected prepared
  [[ "$include_log_in_archive" == "yes" && -f "$LOG_FILE" ]] && prepared+=("$LOG_FILE")

  if [[ ${#prepared[@]} -eq 0 ]]; then
    msg_box "Nothing to Backup" "After filtering missing/special items, nothing remained to back up."
    return 1
  fi

  local dir_dash ext tar_opts=()
  dir_dash="$(echo "$work_dir" | tr '/' '-')"
  local backup_file="$(hostname)${dir_dash}backup-$(date +%Y_%m_%dT%H_%M)"
  if [[ "$compression" == "gz" ]]; then ext="tar.gz"; tar_opts=(-czf)
  else                                  ext="tar";    tar_opts=(-cf); fi

  log "Backup settings: target=$backup_path work_dir=$work_dir compression=$compression retention=$retention_days include_log_in_archive=$include_log_in_archive copy_log_to_backup_path=$copy_log_to_backup_path"
  log "Backup selections: ${selected[*]}"

  $HAS_TTY && whiptail --backtitle "Proxmox VE Host Backup" --title "Backup Running" \
    --infobox "Creating backup archive...\n\nTarget:\n$backup_path" "$UI_H" "$UI_W" || true

  if ! tar "${tar_opts[@]}" "$backup_path/$backup_file.$ext" --absolute-names "${prepared[@]}"; then
    msg_box "Backup Failed" "Backup creation failed. Check reachability/space and log:\n\n$LOG_FILE"
    log "Backup failed: $backup_path/$backup_file.$ext"
    return 1
  fi
  log "Created backup: $backup_path/$backup_file.$ext"

  if [[ "$copy_log_to_backup_path" == "yes" && -f "$LOG_FILE" ]]; then
    cp -f "$LOG_FILE" "$backup_path/$backup_file.log" \
      || log "Failed copying log to $backup_path/$backup_file.log"
  fi

  # Retention: only delete files belonging to THIS host to avoid touching
  # backups from other instances stored in the same directory.
  if [[ "${retention_days:-0}" =~ ^[0-9]+$ ]] && (( retention_days > 0 )); then
    local host_prefix="$(hostname)-"
    find "$backup_path" -maxdepth 1 -type f \
      \( -name "${host_prefix}*.tar" -o -name "${host_prefix}*.tar.gz" -o -name "${host_prefix}*.log" \) \
      -mtime "+${retention_days}" -print -delete >> "$LOG_FILE" 2>&1 || true
  fi

  msg_box "Backup Finished" \
    "Backup created:\n\n$backup_path/$backup_file.$ext\n\nA backup is rendered ineffective when it remains stored on the host."
}

# ---------------------------------------------------------------------------
# Run from saved config (used by cron via --run-config)
# ---------------------------------------------------------------------------
run_from_config() {
  load_config || { echo "No config file found at $CONFIG_FILE"; exit 1; }
  local selected_items=("${SELECTED_ITEMS[@]:-}")
  [[ ${#selected_items[@]} -gt 0 ]] || { echo "Config exists but has no selected items."; exit 1; }
  log "Loaded backup settings from config: $CONFIG_FILE"
  perform_backup \
    "${BACKUP_PATH:-$DEFAULT_BACKUP_PATH}" \
    "${WORK_DIR:-$DEFAULT_WORK_DIR}" \
    "${COMPRESSION:-gz}" \
    "${RETENTION_DAYS:-0}" \
    "${INCLUDE_LOG_IN_ARCHIVE:-no}" \
    "${COPY_LOG_TO_BACKUP_PATH:-no}" \
    "${selected_items[@]}"
}

# ---------------------------------------------------------------------------
# Cron helpers
# ---------------------------------------------------------------------------
build_run_command() {
  local script_ref="$1"
  local source_url="$UPSTREAM_SCRIPT_PAGE_URL"
  local local_path="$DEFAULT_CRON_LOCAL_SCRIPT_PATH"

  local choice
  choice=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
    --title "Cron Script Source" \
    --menu "Choose how cron should execute this script" "$UI_H" "$UI_W" 6 \
    "1" "Use local script path (if available)" \
    "2" "Download script once to local path and run local file" \
    "3" "Always update local file from URL before each cron run" \
    3>&1 1>&2 2>&3) || { log "Cron source selection cancelled"; return 1; }

  case "$choice" in
    1)
      if [[ -f "$script_ref" && "$(basename "$script_ref")" == "host-backup.sh" ]]; then
        printf '%s' "$script_ref --run-config >/dev/null 2>&1"; return 0
      fi
      local_path=$(input_box "Local Script Path" \
        "No local script file detected for this run.\n\nEnter the full path to an already-installed copy of this script:" \
        "$local_path") || return 1
      local_path="${local_path// /}"
      if [[ ! -f "$local_path" ]]; then
        msg_box "Cron Error" "The path does not exist:\n\n$local_path\n\nUse option 2 to download it first."
        log "Cron local path does not exist: $local_path"; return 1
      fi
      printf '%s' "$local_path --run-config >/dev/null 2>&1"
      ;;
    2)
      source_url=$(input_box "Script URL"   "Enter the raw script URL."                "$source_url") || return 1
      local_path=$(input_box "Install Path" "Enter the local path to save the script:" "$local_path") || return 1
      source_url="${source_url// /}"; local_path="${local_path// /}"
      [[ -n "$source_url" && -n "$local_path" ]] || return 1
      if ! download_script_to_local "$source_url" "$local_path"; then
        msg_box "Cron Error" "Failed to download:\n$source_url\n\nto:\n$local_path"
        log "Cron download failed: source=$source_url target=$local_path"; return 1
      fi
      printf '%s' "$local_path --run-config >/dev/null 2>&1"
      ;;
    3)
      source_url=$(input_box "Script URL" \
        "Enter script URL.\n\nCron will re-download and update the local file before each run." \
        "$source_url") || return 1
      local_path=$(input_box "Install Path" "Enter the local path used by cron:" "$local_path") || return 1
      source_url="${source_url// /}"; local_path="${local_path// /}"
      [[ -n "$source_url" && -n "$local_path" ]] || return 1
      printf "bash -lc 'curl -fsSL \"%s\" -o \"%s\" && chmod +x \"%s\" && \"%s\" --run-config' >/dev/null 2>&1" \
        "$source_url" "$local_path" "$local_path" "$local_path"
      ;;
    *) log "Cron source mode invalid or cancelled"; return 1 ;;
  esac
}

cron_install() {
  local schedule
  schedule=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Cron Schedule" \
    --menu "Choose a schedule" "$UI_H" "$UI_W" 6 \
    "1" "Daily at 03:00" \
    "2" "Weekly on Sunday at 03:00" \
    "3" "Monthly on day 1 at 03:00" \
    "4" "Custom cron expression" \
    3>&1 1>&2 2>&3) || return

  local cron_expr schedule_desc
  case "$schedule" in
    1) cron_expr="0 3 * * *"; schedule_desc="Daily at 03:00" ;;
    2) cron_expr="0 3 * * 0"; schedule_desc="Weekly on Sunday at 03:00" ;;
    3) cron_expr="0 3 1 * *"; schedule_desc="Monthly on day 1 at 03:00" ;;
    4)
      cron_expr=$(input_box "Custom Cron" \
        "Enter a cron expression.\n\nExample – every day at 03:30:\n30 3 * * *" \
        "0 3 * * *") || return
      schedule_desc="Custom: $cron_expr"
      ;;
    *) return ;;
  esac

  local cmd
  cmd="$(build_run_command "$SCRIPT_PATH")" || { log "Cron command build failed"; return; }

  local tmp existing
  existing="$(crontab -l 2>/dev/null | sed '/PVE_HOST_BACKUP_MANAGED/d' || true)"
  tmp="$(mktemp)"
  { [[ -n "$existing" ]] && printf '%s\n' "$existing"; printf '%s\n' "$cron_expr $cmd $CRON_TAG"; } > "$tmp"
  crontab "$tmp"; rm -f "$tmp"

  log "Installed cron job: $schedule_desc"
  msg_box "Cron Installed" "The managed cron job was saved.\n\nSchedule:\n$schedule_desc\n\nCommand:\n$cmd"
}

cron_remove() {
  local current
  current="$(crontab -l 2>/dev/null || true)"
  if ! grep -q "PVE_HOST_BACKUP_MANAGED" <<< "$current"; then
    msg_box "Cron Remove" "No managed cron job was found."; return
  fi
  local tmp; tmp="$(mktemp)"
  sed '/PVE_HOST_BACKUP_MANAGED/d' <<< "$current" > "$tmp"
  crontab "$tmp"; rm -f "$tmp"
  log "Removed managed cron job"
  msg_box "Cron Removed" "The managed cron job was removed."
}

update_default_local_script() {
  if download_script_to_local "$UPSTREAM_SCRIPT_PAGE_URL" "$DEFAULT_CRON_LOCAL_SCRIPT_PATH"; then
    msg_box "Script Updated" \
      "Downloaded latest script to:\n\n$DEFAULT_CRON_LOCAL_SCRIPT_PATH\n\nAny existing managed cron job already points to this path."
    log "Updated local cron script: $DEFAULT_CRON_LOCAL_SCRIPT_PATH"
  else
    msg_box "Update Failed" \
      "Failed to download script from:\n\n$UPSTREAM_SCRIPT_PAGE_URL\n\nCheck network access and URL."
    log "Failed updating local cron script from upstream: $UPSTREAM_SCRIPT_PAGE_URL"
  fi
}

cron_menu() {
  local choice
  choice=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Cron Management" \
    --menu "Choose an action" "$UI_H" "$UI_W" 6 \
    "1" "Create or replace managed cron job" \
    "2" "Remove managed cron job" \
    "3" "Show current managed cron entry" \
    "4" "Update local cron script from upstream" \
    3>&1 1>&2 2>&3) || return

  case "$choice" in
    1) cron_install ;;
    2) cron_remove ;;
    3)
      local current
      current="$(crontab -l 2>/dev/null | grep 'PVE_HOST_BACKUP_MANAGED' || true)"
      msg_box "Current Cron" "${current:-No managed cron job found.}"
      ;;
    4) update_default_local_script ;;
  esac
}

# ---------------------------------------------------------------------------
# Log viewer
# ---------------------------------------------------------------------------
show_log_file() {
  mkdir -p "$LOG_DIR"; touch "$LOG_FILE"
  if command -v less >/dev/null 2>&1; then
    less -P "--- q=quit  up/down=scroll  PgUp/PgDn=page  g=top  G=bottom ---" +G "$LOG_FILE"
  else
    local tmp; tmp="$(mktemp)"
    cp "$LOG_FILE" "$tmp" 2>/dev/null || true
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "Host Backup Log" \
      --textbox "$tmp" "$UI_H" "$UI_W"
    rm -f "$tmp"
  fi
}

# ---------------------------------------------------------------------------
# Main interactive wizard
# ---------------------------------------------------------------------------
main_interactive() {
  local backup_path="$DEFAULT_BACKUP_PATH" work_dir="$DEFAULT_WORK_DIR"
  local compression="gz" retention_days="0"
  local include_log_in_archive="no" copy_log_to_backup_path="no"
  local selected=()

  if [[ -f "$CONFIG_FILE" ]]; then
    load_config || true
    backup_path="${BACKUP_PATH:-$DEFAULT_BACKUP_PATH}"
    work_dir="${WORK_DIR:-$DEFAULT_WORK_DIR}"
    compression="${COMPRESSION:-gz}"
    retention_days="${RETENTION_DAYS:-0}"
    include_log_in_archive="${INCLUDE_LOG_IN_ARCHIVE:-no}"
    copy_log_to_backup_path="${COPY_LOG_TO_BACKUP_PATH:-no}"
    selected=("${SELECTED_ITEMS[@]:-}")
    local cleaned=(); dedupe_items selected cleaned; selected=("${cleaned[@]}")

    if yes_no "Existing Settings Found" \
      "A saved config was found at:\n\n$CONFIG_FILE\n\nSaved backup target:\n$backup_path\n\nUse the saved settings for this run?"; then
      if confirm_run_with_summary "$backup_path" "$work_dir" "$compression" "$retention_days" \
          "$include_log_in_archive" "$copy_log_to_backup_path" "${selected[@]}"; then
        perform_backup "$backup_path" "$work_dir" "$compression" "$retention_days" \
          "$include_log_in_archive" "$copy_log_to_backup_path" "${selected[@]}"
        yes_no "Cron Job" "Do you want to create, replace, or remove the scheduled cron job now?" && cron_menu
        return
      fi
    fi
  fi

  backup_path=$(input_box "Directory to backup to:" \
    "Defaults to /root\n\ne.g. /mnt/backups" "$backup_path") || return
  backup_path="$(normalize_backup_path "$backup_path")"

  work_dir=$(input_box "Directory to work in:" \
    "Defaults to /etc/\n\nYou can enter one or more directories separated by comma.\nExample: /etc/, /root/" \
    "$work_dir") || return

  local work_dirs=()
  parse_csv_paths "${work_dir:-$DEFAULT_WORK_DIR}" work_dirs
  [[ ${#work_dirs[@]} -gt 0 ]] || work_dirs=("$DEFAULT_WORK_DIR")
  work_dir="${work_dirs[0]}"

  local compression_choice
  compression_choice=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
    --title "Compression" --menu "Choose archive format" "$UI_H" "$UI_W" 4 \
    "1" "tar.gz (smaller, slower)" \
    "2" "tar (faster, larger)" \
    3>&1 1>&2 2>&3) || return
  [[ "$compression_choice" == "1" ]] && compression="gz" || compression="none"

  retention_days=$(input_box "Retention" \
    "Delete old backups from THIS host ($(hostname)) in the target folder after this many days.\n\nBackups from other hosts (e.g. proxmox, proxmox2...) in the same folder will NOT be touched.\n\nUse 0 to keep all backups." \
    "$retention_days") || return
  retention_days="${retention_days:-0}"
  [[ "$retention_days" =~ ^[0-9]+$ ]] || retention_days="0"

  selected=()
  local dir
  for dir in "${work_dirs[@]}"; do
    local picked=()
    select_items_interactive "$dir" picked || return
    selected+=("${picked[@]}")
  done

  local etc_default="OFF" root_default="OFF" usrlocal_default="OFF" opt_default="OFF" cronspool_default="OFF"
  for dir in "${work_dirs[@]}"; do
    case "$dir" in
      /etc/)            etc_default="ON" ;;
      /root/)           root_default="ON" ;;
      /usr/local/)      usrlocal_default="ON" ;;
      /opt/)            opt_default="ON" ;;
      /var/spool/cron/) cronspool_default="ON" ;;
    esac
  done

  local extras=()
  select_recommended_extras extras "$etc_default" "$root_default" "$usrlocal_default" "$opt_default" "$cronspool_default"
  selected+=("${extras[@]}")

  local include_default="OFF" copy_default="OFF"
  [[ "$include_log_in_archive"  == "yes" ]] && include_default="ON"
  [[ "$copy_log_to_backup_path" == "yes" ]] && copy_default="ON"

  local log_choices
  log_choices=$(whiptail --backtitle "Proxmox VE Host Backup" \
    --title "Backup Log Options" \
    --checklist "Choose one or both log options:" "$UI_H" "$UI_W" 4 \
    "IN_ARCHIVE"          "Include current log file inside the backup archive"   "$include_default" \
    "COPY_NEXT_TO_BACKUP" "Copy log next to archive as same basename (.log)"     "$copy_default" \
    3>&1 1>&2 2>&3) || true

  include_log_in_archive="no"; copy_log_to_backup_path="no"
  local opt
  for opt in $log_choices; do
    opt="$(trim_quotes "$opt")"
    [[ "$opt" == "IN_ARCHIVE" ]]          && include_log_in_archive="yes"
    [[ "$opt" == "COPY_NEXT_TO_BACKUP" ]] && copy_log_to_backup_path="yes"
  done

  local deduped=(); dedupe_items selected deduped; selected=("${deduped[@]}")

  show_selected_summary "$backup_path" "$work_dir" "$compression" "$retention_days" \
    "$include_log_in_archive" "$copy_log_to_backup_path" "${selected[@]}"

  perform_backup "$backup_path" "$work_dir" "$compression" "$retention_days" \
    "$include_log_in_archive" "$copy_log_to_backup_path" "${selected[@]}"

  if yes_no "Save Settings" \
    "Write the current backup settings to a config file for future runs and scheduled jobs?\n\nIf a config already exists, this will overwrite it."; then
    save_config "$backup_path" "$work_dir" "$compression" "$retention_days" \
      "$include_log_in_archive" "$copy_log_to_backup_path" "${selected[@]}"
    msg_box "Settings Saved" "Saved to:\n\n$CONFIG_FILE"
  fi

  yes_no "Cron Job" "Do you want to create, replace, or remove a scheduled cron job now?" && cron_menu
}

# ---------------------------------------------------------------------------
# Main menu
# ---------------------------------------------------------------------------
show_main_menu() {
  while true; do
    header_info
    local choice
    choice=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
      --title "Proxmox VE Host Backup v$SCRIPT_VERSION" \
      --menu "Choose an action" "$UI_H" "$UI_W" "$UI_MENU_H" \
      "1" "Run backup wizard" \
      "2" "Cron management" \
      "3" "Show status and paths" \
      "4" "View backup log file" \
      "5" "Exit" \
      3>&1 1>&2 2>&3) || break

    case "$choice" in
      1) main_interactive ;;
      2) cron_menu ;;
      3)
        local _cron_line _cron_info
        _cron_line="$(crontab -l 2>/dev/null | grep 'PVE_HOST_BACKUP_MANAGED' || true)"
        if [[ -n "$_cron_line" ]]; then
          local _sched _cmd
          _sched="$(awk '{print $1" "$2" "$3" "$4" "$5}' <<< "$_cron_line")"
          _cmd="$(awk '{print $6}' <<< "$_cron_line")"
          _cron_info="Schedule:    $_sched
Script:      $_cmd"
        else
          _cron_info="Not set"
        fi
        msg_box "Status and Paths"           "Config file:
$CONFIG_FILE

Log file:
$LOG_FILE

Runtime script path:
$SCRIPT_PATH

Upstream URL:
$UPSTREAM_SCRIPT_PAGE_URL

Cron job:
$_cron_info"
        ;;
      4) show_log_file ;;
      5) break ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
case "${1:-}" in
  --run-config) run_from_config ;;
  *)
    if yes_no "Proxmox VE Host Backup v$SCRIPT_VERSION" \
      "This will create backups for selected files and directories.\n\nProceed?"; then
      show_main_menu
    fi
    ;;
esac
