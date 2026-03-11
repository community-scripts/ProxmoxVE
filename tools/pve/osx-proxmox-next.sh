#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts | lucid-fabrics
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lucid-fabrics/osx-proxmox-next

# ==============================================================================
# OSX-Proxmox-Next - Automated macOS VM creation for Proxmox VE
# ==============================================================================
# This tool provides a TUI wizard for creating macOS VMs on Proxmox VE.
# Supports: Ventura 13, Sonoma 14, Sequoia 15, Tahoe 26
# ==============================================================================

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func)

function header_info() {
  clear
  cat <<"EOF"
   ____  ______  __    ____                                          _   __          __ 
  / __ \/ ___/ |/ /   / __ \_________  _  ______ ___  ____  _  __   / | / /__  _  __/ /_
 / / / /\__ \|   /   / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  /  |/ / _ \| |/_/ __/
/ /_/ /___/ /   |   / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /|  /  __/>  </ /_  
\____//____/_/|_|  /_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|  /_/ |_/\___/_/|_|\__/  
                                                                                        
EOF
}

# Color definitions
RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
BL=$(echo "\033[36m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
TAB="  "

CM="${TAB}✔️${TAB}${CL}"
CROSS="${TAB}✖️${TAB}${CL}"
INFO="${TAB}💡${TAB}${CL}"

# Constants
REPO_URL="${OSX_NEXT_REPO_URL:-https://github.com/lucid-fabrics/osx-proxmox-next.git}"
REPO_DIR="${OSX_NEXT_REPO_DIR:-/opt/osx-proxmox-next}"
REPO_BRANCH="${OSX_NEXT_BRANCH:-main}"
VENV_DIR="${OSX_NEXT_VENV_DIR:-$REPO_DIR/.venv}"
LOG_FILE="${OSX_NEXT_LOG_FILE:-/var/log/osx-proxmox-next-install.log}"

# Telemetry
APP="osx-proxmox-next"
var_os="tool"

set -euo pipefail
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap cleanup EXIT
trap 'post_update_to_api "failed" "130"' SIGINT
trap 'post_update_to_api "failed" "143"' SIGTERM

function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  post_update_to_api "failed" "${exit_code}"
  echo -e "\n$error_message\n"
}

function cleanup() {
  local exit_code=$?
  if [[ "${POST_TO_API_DONE:-}" == "true" && "${POST_UPDATE_DONE:-}" != "true" ]]; then
    if [[ $exit_code -eq 0 ]]; then
      post_update_to_api "done" "none"
    else
      post_update_to_api "failed" "$exit_code"
    fi
  fi
}

function msg_info() {
  local msg="$1"
  echo -ne "${TAB}${YW}${HOLD}${msg}...${CL}"
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR}${CM}${GN}${msg}${CL}"
}

function msg_error() {
  local msg="$1"
  echo -e "${BFR}${CROSS}${RD}${msg}${CL}"
}

function check_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    header_info
    msg_error "Please run this script as root."
    echo -e "\nExiting..."
    sleep 2
    exit 100
  fi
}

function check_arch() {
  if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    header_info
    msg_error "This script requires an x86_64 (amd64) architecture."
    msg_error "ARM64/ARM systems are not supported for macOS VMs."
    echo -e "\nExiting..."
    sleep 2
    exit 101
  fi
}

function check_pve_version() {
  local PVE_VER
  PVE_VER="$(pveversion | awk -F'/' '{print $2}' | awk -F'-' '{print $1}')"
  
  # Extract major and minor version
  local MAJOR MINOR
  IFS='.' read -r MAJOR MINOR _ <<<"$PVE_VER"
  
  if [[ "$MAJOR" -eq 9 ]]; then
    # Proxmox VE 9.x - fully supported
    msg_ok "Proxmox VE ${PVE_VER} detected (fully supported)"
    return 0
  elif [[ "$MAJOR" -eq 8 ]]; then
    # Proxmox VE 8.x - supported with warning
    msg_ok "Proxmox VE ${PVE_VER} detected"
    echo -e "${YW}${TAB}⚠️  Proxmox VE 8.x support is experimental.${CL}"
    echo -e "${YW}${TAB}   Proxmox VE 9.x is recommended for best compatibility.${CL}"
    echo ""
    if whiptail --backtitle "Proxmox VE Helper Scripts" --title "Version Warning" \
      --yesno "Proxmox VE 8.x detected. OSX-Proxmox-Next is designed for Proxmox VE 9.x.\n\nContinue anyway?" 10 70; then
      return 0
    else
      msg_error "User cancelled installation."
      exit 102
    fi
  else
    msg_error "Unsupported Proxmox VE version: ${PVE_VER}"
    msg_error "This script requires Proxmox VE 8.x or 9.x"
    exit 105
  fi
}

function check_virtualization() {
  # Check for VT-x/AMD-V support
  if grep -qE 'vmx|svm' /proc/cpuinfo; then
    local CPU_VENDOR
    if grep -q 'vmx' /proc/cpuinfo; then
      CPU_VENDOR="Intel"
    else
      CPU_VENDOR="AMD"
    fi
    msg_ok "Virtualization support detected (${CPU_VENDOR})"
  else
    msg_error "No hardware virtualization detected (VT-x/AMD-V)"
    msg_error "macOS VMs require hardware virtualization support."
    echo -e "\nExiting..."
    sleep 2
    exit 103
  fi
}

function install_dependencies() {
  msg_info "Installing dependencies"
  
  if ! $STD apt-get update; then
    msg_error "Failed to update package lists"
    exit 110
  fi
  
  if ! $STD apt-get install -y git python3 python3-venv python3-pip; then
    msg_error "Failed to install required packages"
    exit 111
  fi
  
  msg_ok "Installed dependencies (git, python3, python3-venv, python3-pip)"
}

function sync_repository() {
  if [[ -d "$REPO_DIR/.git" ]]; then
    msg_info "Updating existing repository"
    
    if ! git -C "$REPO_DIR" fetch origin >>"$LOG_FILE" 2>&1; then
      msg_error "Failed to fetch repository updates"
      exit 120
    fi
    
    if ! git -C "$REPO_DIR" checkout "$REPO_BRANCH" >>"$LOG_FILE" 2>&1; then
      msg_error "Failed to checkout branch ${REPO_BRANCH}"
      exit 121
    fi
    
    if ! git -C "$REPO_DIR" reset --hard "origin/$REPO_BRANCH" >>"$LOG_FILE" 2>&1; then
      msg_error "Failed to reset repository"
      exit 122
    fi
    
    # Purge stale bytecode
    find "$REPO_DIR" -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    
    msg_ok "Repository updated to latest ${REPO_BRANCH}"
  else
    msg_info "Cloning repository"
    
    # Remove incomplete directory if exists
    if [[ -d "$REPO_DIR" ]]; then
      rm -rf "$REPO_DIR"
    fi
    
    if ! git clone "$REPO_URL" "$REPO_DIR" >>"$LOG_FILE" 2>&1; then
      msg_error "Failed to clone repository"
      exit 123
    fi
    
    if ! git -C "$REPO_DIR" checkout "$REPO_BRANCH" >>"$LOG_FILE" 2>&1; then
      msg_error "Failed to checkout branch ${REPO_BRANCH}"
      exit 124
    fi
    
    msg_ok "Repository cloned successfully"
  fi
}

function setup_virtualenv() {
  msg_info "Setting up Python virtual environment"
  
  # Remove old venv if exists
  if [[ -d "$VENV_DIR" ]]; then
    rm -rf "$VENV_DIR"
  fi
  
  if ! python3 -m venv "$VENV_DIR" >>"$LOG_FILE" 2>&1; then
    msg_error "Failed to create virtual environment"
    exit 130
  fi
  
  msg_ok "Virtual environment created"
  
  msg_info "Installing Python dependencies"
  
  # Activate venv and install
  # shellcheck source=/dev/null
  source "$VENV_DIR/bin/activate"
  
  if ! pip install --upgrade pip >>"$LOG_FILE" 2>&1; then
    msg_error "Failed to upgrade pip"
    exit 131
  fi
  
  if ! pip install --force-reinstall --no-deps -e "$REPO_DIR" >>"$LOG_FILE" 2>&1; then
    msg_error "Failed to install package (editable mode)"
    exit 132
  fi
  
  if ! pip install -e "$REPO_DIR" >>"$LOG_FILE" 2>&1; then
    msg_error "Failed to install dependencies"
    exit 133
  fi
  
  msg_ok "Python dependencies installed"
}

function launch_tui() {
  msg_ok "Setup complete! Launching OSX-Proxmox-Next TUI..."
  echo ""
  echo -e "${INFO}${YW}The TUI wizard will guide you through macOS VM creation.${CL}"
  echo -e "${INFO}${YW}Supported versions: Ventura 13, Sonoma 14, Sequoia 15, Tahoe 26${CL}"
  echo ""
  
  # shellcheck source=/dev/null
  source "$VENV_DIR/bin/activate"
  exec osx-next
}

function show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "OSX-Proxmox-Next - Automated macOS VM creation for Proxmox VE"
  echo ""
  echo "Options:"
  echo "  -h, --help     Show this help message"
  echo "  -u, --update   Update to latest version"
  echo "  -v, --version  Show version information"
  echo ""
  echo "Environment Variables:"
  echo "  OSX_NEXT_REPO_URL     Custom repository URL"
  echo "  OSX_NEXT_REPO_DIR     Custom installation directory"
  echo "  OSX_NEXT_BRANCH       Git branch to use (default: main)"
  echo "  OSX_NEXT_VENV_DIR     Custom venv directory"
  echo "  OSX_NEXT_LOG_FILE     Custom log file path"
  echo ""
  echo "Examples:"
  echo "  $0                    # Install and launch TUI"
  echo "  $0 --update           # Update to latest version"
  echo ""
}

function show_version() {
  echo "OSX-Proxmox-Next Installer v1.0.0"
  echo "Repository: $REPO_URL"
  echo "Branch: $REPO_BRANCH"
  if [[ -f "$REPO_DIR/pyproject.toml" ]]; then
    INSTALLED_VER=$(grep -oP 'version\s*=\s*"\K[^"]+' "$REPO_DIR/pyproject.toml" 2>/dev/null || echo "unknown")
    echo "Installed Version: $INSTALLED_VER"
  fi
}

function main() {
  # Parse arguments
  case "${1:-}" in
    -h|--help)
      show_usage
      exit 0
      ;;
    -v|--version)
      show_version
      exit 0
      ;;
    -u|--update)
      header_info
      echo -e "${YW}Updating OSX-Proxmox-Next...${CL}"
      check_root
      install_dependencies
      sync_repository
      setup_virtualenv
      msg_ok "Update complete!"
      exit 0
      ;;
  esac
  
  header_info
  
  # Welcome message
  echo -e "${YW}${TAB}OSX-Proxmox-Next - macOS VM Creation Tool${CL}"
  echo -e "${YW}${TAB}Repository: https://github.com/lucid-fabrics/osx-proxmox-next${CL}"
  echo ""
  
  # Confirmation
  if ! whiptail --backtitle "Proxmox VE Helper Scripts" --title "OSX-Proxmox-Next" \
    --yesno "This will install and launch OSX-Proxmox-Next.\n\nA TUI wizard for creating macOS VMs on Proxmox VE.\n\nProceed with installation?" 12 70; then
    echo -e "${CROSS}${RD}User cancelled installation.${CL}\n"
    exit 0
  fi
  
  # Pre-flight checks
  check_root
  check_arch
  check_pve_version
  check_virtualization
  
  # Post telemetry start
  post_to_api_vm
  
  # Installation
  install_dependencies
  sync_repository
  setup_virtualenv
  
  # Launch
  launch_tui
}

main "$@"
