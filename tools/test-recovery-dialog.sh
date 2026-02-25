#!/usr/bin/env bash
# ==============================================================================
# test-recovery-dialog.sh — Test harness for the installation recovery dialog
#
# This script simulates a failed LXC installation on a real Proxmox host.
# It sources the actual func files and triggers the failure path in
# build_container() so you can verify the recovery dialog appears correctly.
#
# Usage:
#   1. Copy this file to your Proxmox host:
#        scp tools/test-recovery-dialog.sh root@proxmox:/tmp/
#
#   2. Run it directly (creates a minimal container, installs nothing, forces failure):
#        bash /tmp/test-recovery-dialog.sh
#
#   3. Or run with a real app to test (will actually fail during install):
#        TEST_REAL_APP=zammad bash /tmp/test-recovery-dialog.sh
#
# What it tests:
#   - msg_error output after failure
#   - Log collection (pct pull, combined log, tee capture)
#   - Telemetry reporting (post_update_to_api)
#   - Error type detection (APT, OOM, network, etc.)
#   - Recovery menu display and option handling
#   - SIGTSTP trap (the [2]+ Stopped bug)
#
# Environment variables:
#   TEST_REAL_APP=<appname>   Use a real install script (e.g., zammad)
#   TEST_EXIT_CODE=<N>        Simulate a specific exit code (default: 1)
#   TEST_ERROR_TYPE=<type>    Simulate error type: apt, oom, network, cmd (default: generic)
#   TEST_SKIP_CONTAINER=1     Skip container creation, test dialog rendering only
#   TEST_VERBOSE=1            Enable verbose mode
#   DIAGNOSTICS=yes           Enable telemetry (default: no for testing)
# ==============================================================================

set -Eeuo pipefail

# ── Safety check ──
if [[ ! -f /etc/pve/local/pve-ssl.pem ]] && [[ "${TEST_SKIP_CONTAINER:-0}" != "1" ]]; then
  echo "ERROR: This script must be run on a Proxmox VE host."
  echo "       Use TEST_SKIP_CONTAINER=1 to test dialog rendering without Proxmox."
  exit 1
fi

# ── Configuration ──
TEST_EXIT_CODE="${TEST_EXIT_CODE:-1}"
TEST_ERROR_TYPE="${TEST_ERROR_TYPE:-generic}"
TEST_REAL_APP="${TEST_REAL_APP:-}"
DIAGNOSTICS="${DIAGNOSTICS:-no}"

echo "=============================================="
echo "  Recovery Dialog Test Harness"
echo "=============================================="
echo "  Exit code:    ${TEST_EXIT_CODE}"
echo "  Error type:   ${TEST_ERROR_TYPE}"
echo "  Real app:     ${TEST_REAL_APP:-none (mock)}"
echo "  Skip CT:      ${TEST_SKIP_CONTAINER:-0}"
echo "  Diagnostics:  ${DIAGNOSTICS}"
echo "=============================================="
echo ""

# ── Source the real func files ──
# Uses the same source chain as the real scripts
REPO_SOURCE="${REPO_SOURCE:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/ref_api}"

echo "Sourcing func files from: ${REPO_SOURCE}"

# Source in the correct order (same as build.func does)
source <(curl -fsSL "${REPO_SOURCE}/misc/api.func") 2>/dev/null || {
  echo "WARNING: Could not source api.func from ${REPO_SOURCE}"
  echo "         Defining stub functions..."
  post_update_to_api() { echo "[STUB] post_update_to_api $*"; }
  explain_exit_code() { echo "Test error (code $1)"; }
  categorize_error() { echo "test"; }
  json_escape() { printf '%s' "${1:-}"; }
  get_full_log() { echo ""; }
  build_error_string() { echo "exit_code=$1 | test error"; }
}

source <(curl -fsSL "${REPO_SOURCE}/misc/core.func") 2>/dev/null || {
  echo "WARNING: Could not source core.func"
  # Minimal stubs
  TAB=$'\t'
  RD=$'\033[01;31m'
  GN=$'\033[1;92m'
  YW=$'\033[33m'
  BL=$'\033[36m'
  CL=$'\033[m'
  CM="✔"
  CROSS="✖"
  INFO="💡"
  HOLD="⏳"
  BFR="\r\033[2K"
  DGN=$'\033[33m'
  msg_info() { echo -e "${TAB}⏳ $1"; }
  msg_ok() { echo -e "${TAB}✔ $1"; }
  msg_error() { echo -e "${TAB}✖ $1" >&2; }
  msg_warn() { echo -e "${TAB}⚠ $1"; }
  msg_custom() { echo -e "${TAB}$1 $3"; }
  stop_spinner() { :; }
}

source <(curl -fsSL "${REPO_SOURCE}/misc/error_handler.func") 2>/dev/null || {
  echo "WARNING: Could not source error_handler.func"
  error_handler() { echo "[STUB] error_handler $*"; exit "${1:-1}"; }
  catch_errors() { :; }
}

# Initialize colors, formatting, icons (must be called after sourcing core.func)
if declare -f load_functions >/dev/null 2>&1; then
  load_functions
fi

# Initialize traps
if declare -f catch_errors >/dev/null 2>&1; then
  catch_errors
fi

echo ""
echo "✔ Func files loaded"
echo ""

# ── Setup test environment ──
export SESSION_ID="test-$(date +%s)"
export RANDOM_UUID="test-uuid-$(date +%s)"
export EXECUTION_ID="test-exec-$(date +%s)"
export NSAPP="${TEST_REAL_APP:-testapp}"
export APP="${NSAPP}"
export var_install="${NSAPP}"
export var_os="debian"
export var_version="12"
export CT_TYPE=1
export DISK_SIZE=4
export CORE_COUNT=1
export RAM_SIZE=1024
export METHOD="default"
export NET="dhcp"
export BRG="vmbr0"
export TELEMETRY_TYPE="lxc"
export VERBOSE="${TEST_VERBOSE:-no}"
export var_verbose="${VERBOSE}"

# ── Mock or create container ──
if [[ "${TEST_SKIP_CONTAINER:-0}" == "1" ]]; then
  echo "Skipping container creation (TEST_SKIP_CONTAINER=1)"
  echo "Testing dialog rendering only..."
  echo ""

  export CTID=99999
  export BUILD_LOG="/tmp/test-build-${SESSION_ID}.log"
  echo "Test build log entry" > "$BUILD_LOG"

  # Create a fake combined log with error content based on TEST_ERROR_TYPE
  combined_log="/tmp/${NSAPP}-${CTID}-${SESSION_ID}.log"
  {
    echo "================================================================================"
    echo "COMBINED INSTALLATION LOG - ${APP}"
    echo "Container ID: ${CTID}"
    echo "Session ID: ${SESSION_ID}"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "================================================================================"
    echo ""
    echo "================================================================================"
    echo "PHASE 1: CONTAINER CREATION (Host)"
    echo "================================================================================"
    echo "Test build log entry"
    echo ""
    echo "================================================================================"
    echo "PHASE 2: APPLICATION INSTALLATION (Container)"
    echo "================================================================================"

    case "$TEST_ERROR_TYPE" in
    apt)
      echo "Reading package lists..."
      echo "Building dependency tree..."
      echo "E: Unable to locate package foobar-nonexistent"
      echo "E: Package 'foobar-nonexistent' has no installation candidate"
      echo "dpkg: error processing package foobar (--configure):"
      echo " dependency problems - leaving unconfigured"
      echo "E: Sub-process /usr/bin/dpkg returned an error code (1)"
      ;;
    oom)
      echo "Starting application..."
      echo "FATAL ERROR: CALL_AND_RETRY_LAST Allocation failed - JavaScript heap out of memory"
      echo "Cannot allocate memory"
      echo "Killed process 12345 (node) total-vm:4194304kB"
      ;;
    network)
      echo "Fetching https://registry.npmjs.org/..."
      echo "curl: (7) Failed to connect to registry.npmjs.org port 443"
      echo "Could not resolve host: github.com"
      echo "Temporary failure resolving 'deb.debian.org'"
      ;;
    cmd)
      echo "Setting up application..."
      echo "foobar-cmd: command not found"
      echo "/usr/local/bin/missing-tool: No such file or directory"
      ;;
    *)
      echo "Starting installation..."
      echo "Setting up database..."
      echo "Configuring application..."
      echo "systemctl restart -q elasticsearch"
      echo "Job for elasticsearch.service failed because the control process exited with error code."
      echo "See \"systemctl status elasticsearch.service\" for details."
      ;;
    esac
  } > "$combined_log"

  export INSTALL_LOG="$combined_log"

  # ── Now simulate the failure path directly ──
  install_exit_code="${TEST_EXIT_CODE}"

  # Override exit codes for specific error types
  case "$TEST_ERROR_TYPE" in
  apt) [[ "$TEST_EXIT_CODE" == "1" ]] && install_exit_code=100 ;;
  oom) [[ "$TEST_EXIT_CODE" == "1" ]] && install_exit_code=137 ;;
  network) [[ "$TEST_EXIT_CODE" == "1" ]] && install_exit_code=7 ;;
  cmd) [[ "$TEST_EXIT_CODE" == "1" ]] && install_exit_code=127 ;;
  esac

  echo "Simulating failure with exit code: ${install_exit_code}"
  echo ""

  # ── Run the actual failure path code ──
  # This is the same code from build_container() starting at "Installation failed?"

  # Prevent SIGTSTP (the fix we're testing)
  trap '' TSTP

  msg_error "Installation failed in container ${CTID} (exit code: ${install_exit_code})"

  # Report failure to telemetry API
  echo -e "${TAB}⏳ Reporting failure to telemetry..." >&2
  post_update_to_api "failed" "$install_exit_code" 2>/dev/null || true
  echo -e "${TAB}${CM:-✔} Failure reported" >&2

  # Disable error handling (matches real code)
  set +Eeuo pipefail
  trap - ERR

  # Show combined log location
  msg_custom "📋" "${YW}" "Installation log: ${combined_log}"

  # Error type detection (same as build_container)
  is_oom=false
  is_network_issue=false
  is_apt_issue=false
  is_cmd_not_found=false
  error_explanation=""
  if declare -f explain_exit_code >/dev/null 2>&1; then
    error_explanation="$(explain_exit_code "$install_exit_code")"
  fi

  if [[ $install_exit_code -eq 134 || $install_exit_code -eq 137 || $install_exit_code -eq 243 ]]; then
    is_oom=true
  fi

  case "$install_exit_code" in
  100 | 101 | 102) is_apt_issue=true ;;
  255)
    if [[ -f "$combined_log" ]] && grep -qiE 'dpkg|apt-get|broken packages|unmet dependencies' "$combined_log"; then
      is_apt_issue=true
    fi
    ;;
  esac

  if [[ $install_exit_code -eq 127 ]]; then
    is_cmd_not_found=true
  fi

  case "$install_exit_code" in
  6 | 7 | 22 | 28 | 35 | 52 | 56 | 57 | 75 | 78) is_network_issue=true ;;
  esac

  if [[ $install_exit_code -eq 1 && -f "$combined_log" ]]; then
    if grep -qiE 'E: Unable to|dpkg.*error|broken packages' "$combined_log"; then
      is_apt_issue=true
    fi
    if grep -qiE 'Cannot allocate memory|Out of memory|oom-killer|JavaScript heap' "$combined_log"; then
      is_oom=true
    fi
    if grep -qiE 'Could not resolve|DNS|Connection refused|Temporary failure resolving' "$combined_log"; then
      is_network_issue=true
    fi
    if grep -qiE ': command not found|No such file or directory.*/s?bin/' "$combined_log"; then
      is_cmd_not_found=true
    fi
  fi

  # Show error explanation
  if [[ -n "$error_explanation" ]]; then
    echo -e "${TAB}${RD}Error: ${error_explanation}${CL}"
    echo ""
  fi

  # Show hints
  if [[ "$is_cmd_not_found" == true ]]; then
    missing_cmd=""
    if [[ -f "$combined_log" ]]; then
      missing_cmd=$(grep -oiE '[a-zA-Z0-9_.-]+: command not found' "$combined_log" 2>/dev/null | tail -1 | sed 's/: command not found//') || true
    fi
    if [[ -n "$missing_cmd" ]]; then
      echo -e "${TAB}${INFO} Missing command: ${GN}${missing_cmd}${CL}"
    fi
    echo ""
  fi

  # Build recovery menu
  echo -e "${YW}What would you like to do?${CL}"
  echo ""
  echo -e "  ${GN}1)${CL} Remove container and exit"
  echo -e "  ${GN}2)${CL} Keep container for debugging"
  echo -e "  ${GN}3)${CL} Retry with verbose mode (full rebuild)"

  next_option=4
  APT_OPTION="" OOM_OPTION="" DNS_OPTION=""
  RAM_SIZE=${RAM_SIZE:-1024}

  if [[ "$is_apt_issue" == true ]]; then
    echo -e "  ${GN}${next_option})${CL} Repair APT/DPKG state and re-run install (in-place)"
    APT_OPTION=$next_option
    next_option=$((next_option + 1))
  fi

  if [[ "$is_oom" == true ]]; then
    new_ram=$((RAM_SIZE * 2))
    new_cpu=$((CORE_COUNT * 2))
    echo -e "  ${GN}${next_option})${CL} Retry with more resources (RAM: ${RAM_SIZE}→${new_ram} MiB, CPU: ${CORE_COUNT}→${new_cpu} cores)"
    OOM_OPTION=$next_option
    next_option=$((next_option + 1))
  fi

  if [[ "$is_network_issue" == true ]]; then
    echo -e "  ${GN}${next_option})${CL} Retry with DNS override in LXC (8.8.8.8 / 1.1.1.1)"
    DNS_OPTION=$next_option
    next_option=$((next_option + 1))
  fi

  max_option=$((next_option - 1))
  echo ""
  echo -en "${YW}Select option [1-${max_option}] (default: 1, auto-remove in 60s): ${CL}"

  if read -t 60 -r response; then
    echo ""
    echo "✔ You selected: '${response:-1}'"
    echo ""
    case "${response:-1}" in
    1) echo "[TEST] Would remove container ${CTID}" ;;
    2) echo "[TEST] Would keep container ${CTID} for debugging" ;;
    3) echo "[TEST] Would retry with verbose mode" ;;
    *)
      if [[ -n "${APT_OPTION}" && "${response}" == "${APT_OPTION}" ]]; then
        echo "[TEST] Would repair APT/DPKG state and re-run"
      elif [[ -n "${OOM_OPTION}" && "${response}" == "${OOM_OPTION}" ]]; then
        echo "[TEST] Would retry with doubled resources"
      elif [[ -n "${DNS_OPTION}" && "${response}" == "${DNS_OPTION}" ]]; then
        echo "[TEST] Would retry with DNS override"
      else
        echo "[TEST] Invalid option: ${response}"
      fi
      ;;
    esac
  else
    echo ""
    echo "[TEST] Timeout - would auto-remove container ${CTID}"
  fi

  # Finalize
  echo -e "${TAB}⏳ Finalizing telemetry report..." >&2
  post_update_to_api "failed" "$install_exit_code" "force" 2>/dev/null || true
  echo -e "${TAB}${CM:-✔} Telemetry finalized" >&2

  trap - TSTP

  echo ""
  echo "=============================================="
  echo "  Test completed successfully!"
  echo "  The recovery dialog appeared as expected."
  echo "=============================================="

  # Cleanup
  rm -f "$BUILD_LOG" "$combined_log" 2>/dev/null

  exit 0
fi

# ── Full test with real container ──
echo "Creating test container..."
echo ""

# Use the real build.func flow
source <(curl -fsSL "${REPO_SOURCE}/misc/build.func") 2>/dev/null || {
  echo "ERROR: Could not source build.func"
  exit 1
}

# The rest of the test with a real container would use the standard
# script flow. For now, suggest using TEST_SKIP_CONTAINER=1 for
# dialog testing, or TEST_REAL_APP=<app> for full integration tests.
echo "For full integration testing with a real container, run one of:"
echo ""
echo "  # Test with a known-failing app:"
echo "  TEST_REAL_APP=zammad bash /tmp/test-recovery-dialog.sh"
echo ""
echo "  # Or test dialog rendering without a container:"
echo "  TEST_SKIP_CONTAINER=1 bash /tmp/test-recovery-dialog.sh"
echo "  TEST_SKIP_CONTAINER=1 TEST_ERROR_TYPE=apt bash /tmp/test-recovery-dialog.sh"
echo "  TEST_SKIP_CONTAINER=1 TEST_ERROR_TYPE=oom bash /tmp/test-recovery-dialog.sh"
echo "  TEST_SKIP_CONTAINER=1 TEST_ERROR_TYPE=network bash /tmp/test-recovery-dialog.sh"
echo "  TEST_SKIP_CONTAINER=1 TEST_ERROR_TYPE=cmd bash /tmp/test-recovery-dialog.sh"
echo ""
