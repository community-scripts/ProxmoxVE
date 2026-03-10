#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Codex (GPT-5.2-Codex)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/community-scripts/ProxmoxVE

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="/var/log/arr-suite-installer"
STATE_DIR="/var/lib/arr-suite-installer"
REPORT_JSON=""
MODE="all"
STRICT_MODE=0
FORCE_MODE=0
RESUME_MODE=0
DRY_RUN=0
SKIP_APPS_RAW=""
ONLY_APPS_RAW=""

MIN_CPU=4
MIN_RAM_MB=8192
MIN_DISK_MB=51200

mkdir -p "$LOG_DIR" "$STATE_DIR"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
RUN_LOG="$LOG_DIR/run-$RUN_ID.log"
STATE_FILE="$STATE_DIR/last-run.state"

# Known services/timers and default web ports for summary checks
# Format: slug|install_script|services(comma)|timers(comma)|port
APPS=(
  "autobrr|autobrr-install.sh|autobrr||7474"
  "bazarr|bazarr-install.sh|bazarr||6767"
  "byparr|byparr-install.sh|byparr||8191"
  "cleanuparr|cleanuparr-install.sh|cleanuparr||11011"
  "configarr|configarr-install.sh|configarr-task.service|configarr-task.timer|"
  "cross-seed|cross-seed-install.sh|cross-seed||2468"
  "dispatcharr|dispatcharr-install.sh|dispatcharr,dispatcharr-celery,dispatcharr-celerybeat,dispatcharr-daphne||9191"
  "flaresolverr|flaresolverr-install.sh|flaresolverr||8191"
  "kapowarr|kapowarr-install.sh|kapowarr||5656"
  "lidarr|lidarr-install.sh|lidarr||8686"
  "mediamanager|mediamanager-install.sh|mediamanager||5000"
  "mylar3|mylar3-install.sh|mylar3||8090"
  "notifiarr|notifiarr-install.sh|notifiarr||5454"
  "profilarr|profilarr-install.sh|profilarr||6868"
  "prowlarr|prowlarr-install.sh|prowlarr||9696"
  "radarr|radarr-install.sh|radarr||7878"
  "recyclarr|recyclarr-install.sh|recyclarr||"
  "scraparr|scraparr-install.sh|scraparr||7100"
  "sonarr|sonarr-install.sh|sonarr||8989"
  "sonobarr|sonobarr-install.sh|sonobarr||3130"
  "sportarr|sportarr-install.sh|sportarr||8787"
  "tdarr|tdarr-install.sh|tdarr,tdarr-node||8265"
  "tracearr|tracearr-install.sh|tracearr||3100"
  "umlautadaptarr|umlautadaptarr-install.sh|umlautadaptarr||5005"
  "whisparr|whisparr-install.sh|whisparr||6969"
  "wizarr|wizarr-install.sh|wizarr||5690"
)

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Deploy *arr ecosystem apps in ONE existing LXC (no Docker), using repository install scripts.

Options:
  --all                    Install all supported apps (default)
  --apps a,b,c             Install only selected app slugs
  --skip a,b,c             Skip selected app slugs
  --strict                 Stop on first app failure
  --force                  Re-run installers even when service already appears active
  --resume                 Resume from last failed/not-run app in state file
  --dry-run                Print execution plan; do not execute installers
  --json-report FILE       Write JSON report to FILE
  -h, --help               Show this help

Supported slugs:
  $(printf '%s\n' "${APPS[@]}" | cut -d'|' -f1 | paste -sd, -)
USAGE
}

log() {
  local level="$1"; shift
  local msg="$*"
  echo "[$(date +'%F %T')] [$level] $msg" | tee -a "$RUN_LOG"
}

die() {
  log "ERROR" "$*"
  exit 1
}

contains_csv() {
  local needle="$1" csv="$2"
  [[ ",$csv," == *",$needle,"* ]]
}

check_root() {
  [[ "$EUID" -eq 0 ]] || die "Run as root inside the LXC."
}

check_os() {
  local os_id version_id
  os_id="$(. /etc/os-release; echo "${ID:-}")"
  version_id="$(. /etc/os-release; echo "${VERSION_ID:-}")"
  [[ "$os_id" == "debian" ]] || die "This script currently targets Debian LXCs only. Detected: $os_id"
  if [[ "${version_id%%.*}" -lt 12 ]]; then
    die "Debian 12+ recommended. Detected version: $version_id"
  fi
}

check_resources() {
  local cpus ram_mb disk_mb
  cpus="$(nproc)"
  ram_mb="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)"
  disk_mb="$(df -Pm / | awk 'NR==2 {print $4}')"

  log "INFO" "Detected resources -> CPU: ${cpus}, RAM: ${ram_mb}MB, Free disk: ${disk_mb}MB"

  (( cpus >= MIN_CPU )) || log "WARN" "Recommended CPU >= ${MIN_CPU}; detected ${cpus}."
  (( ram_mb >= MIN_RAM_MB )) || log "WARN" "Recommended RAM >= ${MIN_RAM_MB}MB; detected ${ram_mb}MB."
  (( disk_mb >= MIN_DISK_MB )) || log "WARN" "Recommended free disk >= ${MIN_DISK_MB}MB; detected ${disk_mb}MB."
}

network_preflight() {
  if ! ping -c1 -W2 1.1.1.1 >/dev/null 2>&1 && ! ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then
    die "No internet connectivity detected (ping checks failed)."
  fi

  if ! getent hosts raw.githubusercontent.com >/dev/null; then
    die "DNS resolution failed for raw.githubusercontent.com"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        MODE="all"
        ;;
      --apps)
        MODE="only"
        ONLY_APPS_RAW="${2:-}"
        shift
        ;;
      --skip)
        SKIP_APPS_RAW="${2:-}"
        shift
        ;;
      --strict)
        STRICT_MODE=1
        ;;
      --force)
        FORCE_MODE=1
        ;;
      --resume)
        RESUME_MODE=1
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      --json-report)
        REPORT_JSON="${2:-}"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
    shift
  done
}

validate_slug() {
  local slug="$1"
  printf '%s\n' "${APPS[@]}" | cut -d'|' -f1 | grep -qx "$slug"
}

build_selection() {
  local selected=() slug
  local all_slugs
  mapfile -t all_slugs < <(printf '%s\n' "${APPS[@]}" | cut -d'|' -f1)

  if [[ "$MODE" == "all" ]]; then
    selected=("${all_slugs[@]}")
  else
    IFS=',' read -r -a selected <<<"$ONLY_APPS_RAW"
    [[ ${#selected[@]} -gt 0 ]] || die "--apps provided but empty"
    for slug in "${selected[@]}"; do
      validate_slug "$slug" || die "Unknown app in --apps: $slug"
    done
  fi

  if [[ -n "$SKIP_APPS_RAW" ]]; then
    IFS=',' read -r -a skip_list <<<"$SKIP_APPS_RAW"
    for slug in "${skip_list[@]}"; do
      validate_slug "$slug" || die "Unknown app in --skip: $slug"
    done

    local filtered=()
    for slug in "${selected[@]}"; do
      if contains_csv "$slug" "$SKIP_APPS_RAW"; then
        continue
      fi
      filtered+=("$slug")
    done
    selected=("${filtered[@]}")
  fi

  # Resume mode: trim all entries before last cursor
  if (( RESUME_MODE )) && [[ -f "$STATE_FILE" ]]; then
    local cursor
    cursor="$(awk -F= '/^next_slug=/{print $2}' "$STATE_FILE" 2>/dev/null || true)"
    if [[ -n "$cursor" ]] && contains_csv "$cursor" "$(IFS=,; echo "${selected[*]}")"; then
      local resumed=() seen=0
      for slug in "${selected[@]}"; do
        if [[ "$slug" == "$cursor" ]]; then
          seen=1
        fi
        (( seen )) && resumed+=("$slug")
      done
      selected=("${resumed[@]}")
      log "INFO" "Resume mode active. Starting from '$cursor'."
    fi
  fi

  [[ ${#selected[@]} -gt 0 ]] || die "Selection is empty after applying filters."
  SELECTED_APPS=("${selected[@]}")
}

get_app_meta() {
  local slug="$1"
  printf '%s\n' "${APPS[@]}" | awk -F'|' -v s="$slug" '$1==s {print; exit}'
}

service_active() {
  local svc="$1"
  systemctl is-active --quiet "$svc"
}

should_skip_installed() {
  local services_csv="$1"
  (( FORCE_MODE )) && return 1
  [[ -z "$services_csv" ]] && return 1

  IFS=',' read -r -a svcs <<<"$services_csv"
  local svc
  for svc in "${svcs[@]}"; do
    service_active "$svc" || return 1
  done
  return 0
}

run_installer() {
  local slug="$1" install_script="$2"
  local script_path="$SCRIPT_DIR/$install_script"

  [[ -f "$script_path" ]] || die "Missing installer for $slug: $script_path"

  if (( DRY_RUN )); then
    log "INFO" "[dry-run] Would run: bash $script_path"
    return 0
  fi

  export FUNCTIONS_FILE_PATH
  FUNCTIONS_FILE_PATH="$(cat "$ROOT_DIR/misc/install.func")"

  log "INFO" "Starting install: $slug"
  if bash "$script_path" >>"$RUN_LOG" 2>&1; then
    log "INFO" "Completed install: $slug"
    return 0
  fi

  log "ERROR" "Failed install: $slug (see $RUN_LOG)"
  return 1
}

check_port() {
  local port="$1"
  [[ -z "$port" ]] && return 2
  ss -lntp | awk '{print $4}' | grep -qE "[:.]${port}$"
}

write_state() {
  local next_slug="$1"
  {
    echo "run_id=$RUN_ID"
    echo "next_slug=$next_slug"
  } >"$STATE_FILE"
}

emit_json_report() {
  local file="$1"
  [[ -z "$file" ]] && return 0
  mkdir -p "$(dirname "$file")"
  {
    echo "{"
    echo "  \"run_id\": \"$RUN_ID\"," 
    echo "  \"log\": \"$RUN_LOG\"," 
    echo "  \"results\": ["
    local i=0
    for row in "${RESULT_ROWS[@]}"; do
      IFS='|' read -r slug status services timers port svc_state timer_state port_state <<<"$row"
      [[ $i -gt 0 ]] && echo "    ,"
      cat <<ROW
    {
      \"app\": \"$slug\",
      \"status\": \"$status\",
      \"services\": \"$services\",
      \"timers\": \"$timers\",
      \"port\": \"$port\",
      \"services_state\": \"$svc_state\",
      \"timers_state\": \"$timer_state\",
      \"port_state\": \"$port_state\"
    }
ROW
      ((i+=1))
    done
    echo "  ]"
    echo "}"
  } >"$file"
  log "INFO" "Wrote JSON report: $file"
}

print_summary() {
  echo
  echo "===== arr-suite deployment summary ====="
  printf '%-16s %-12s %-18s %-16s %-10s\n' "APP" "RESULT" "SERVICES" "TIMERS" "PORT"
  printf '%-16s %-12s %-18s %-16s %-10s\n' "----------------" "------------" "------------------" "----------------" "----------"

  for row in "${RESULT_ROWS[@]}"; do
    IFS='|' read -r slug status services timers port svc_state timer_state port_state <<<"$row"
    local services_label="$svc_state"
    local timer_label="$timer_state"
    local port_label="$port_state"

    [[ -z "$services" ]] && services_label="n/a"
    [[ -z "$timers" ]] && timer_label="n/a"
    [[ -z "$port" ]] && port_label="n/a"

    printf '%-16s %-12s %-18s %-16s %-10s\n' "$slug" "$status" "$services_label" "$timer_label" "$port_label"
  done
  echo
  echo "Log file: $RUN_LOG"
}

main() {
  parse_args "$@"
  check_root
  check_os
  check_resources
  network_preflight
  build_selection

  log "INFO" "Selected apps: $(IFS=,; echo "${SELECTED_APPS[*]}")"
  (( DRY_RUN )) && log "INFO" "Dry-run mode enabled"

  RESULT_ROWS=()
  local slug meta install_script services timers port status
  for slug in "${SELECTED_APPS[@]}"; do
    meta="$(get_app_meta "$slug")"
    IFS='|' read -r _ install_script services timers port <<<"$meta"

    write_state "$slug"

    if should_skip_installed "$services"; then
      status="skipped-active"
      log "INFO" "Skipping $slug (all declared services already active); use --force to override"
    else
      if run_installer "$slug" "$install_script"; then
        status="installed"
      else
        status="failed"
        if (( STRICT_MODE )); then
          log "ERROR" "Strict mode enabled: aborting on first failure ($slug)."
          # Collect state for this failed app before aborting
          :
        fi
      fi
    fi

    local svc_state="unknown" timer_state="unknown" port_state="unknown"
    if [[ -n "$services" ]]; then
      svc_state="ok"
      IFS=',' read -r -a svc_list <<<"$services"
      for s in "${svc_list[@]}"; do
        if ! systemctl is-active --quiet "$s"; then
          svc_state="degraded"
          break
        fi
      done
    fi

    if [[ -n "$timers" ]]; then
      timer_state="ok"
      IFS=',' read -r -a timer_list <<<"$timers"
      for t in "${timer_list[@]}"; do
        if ! systemctl is-enabled --quiet "$t"; then
          timer_state="degraded"
          break
        fi
      done
    fi

    if [[ -n "$port" ]]; then
      if check_port "$port"; then
        port_state="listening"
      else
        port_state="closed"
      fi
    fi

    RESULT_ROWS+=("$slug|$status|$services|$timers|$port|$svc_state|$timer_state|$port_state")

    if [[ "$status" == "failed" ]] && (( STRICT_MODE )); then
      emit_json_report "$REPORT_JSON"
      print_summary
      exit 1
    fi
  done

  write_state ""
  emit_json_report "$REPORT_JSON"
  print_summary
}

main "$@"
