#!/usr/bin/env bash
# Copyright (c) 2021-2025 PeterSuh-Q3
# Author: PeterSuh-Q3
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
     _    __  __ ____   ____ ____  _   _   _____
    / \  |  \/  |  _ \ / ___|  _ \| | | | |_   _|___  _ __
   / _ \ | |\/| | | | | |  _| |_) | | | |   | |/ _ \| '_ \
  / ___ \| |  | | |_| | |_| |  __/| |_| |   | | (_) | |_) |
 /_/   \_\_|  |_|____/ \____|_|    \___/    |_|\___/| .__/
                                                    |_|
EOF
}

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\r\033[K"
HOLD="-"
CM="${GN}✓${CL}"

silent() { "$@" >/dev/null 2>&1; }
set -e

header_info
echo "Loading..."

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

function msg_error() { echo -e "${RD}✗ $1${CL}"; }

# This function checks if system has required packages for compilation
check_system() {
  if ! command -v dpkg &> /dev/null; then
    msg_error "This script requires a Debian-based system (Ubuntu, Debian, etc.)"
    exit 1
  fi
  
  # Check if running as root
  if [[ $EUID -ne 0 ]]; then
    msg_error "This script must be run as root"
    exit 1
  fi
}

# Check if amdgpu_top is already installed
check_installed() {
  if command -v amdgpu_top &> /dev/null; then
    return 0
  else
    return 1
  fi
}

install() {
  header_info
  
  if check_installed; then
    while true; do
      read -p "amdgpu_top is already installed. Do you want to reinstall? (y/n)? " yn
      case $yn in
      [Yy]*) break ;;
      [Nn]*) exit ;;
      *) echo "Please answer yes or no." ;;
      esac
    done
  else
    while true; do
      read -p "Are you sure you want to install amdgpu_top? Proceed(y/n)? " yn
      case $yn in
      [Yy]*) break ;;
      [Nn]*) exit ;;
      *) echo "Please answer yes or no." ;;
      esac
    done
  fi
  
  read -r -p "Verbose mode? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && STD="" || STD="silent"
  
  msg_info "Updating package lists and installing build dependencies"
  $STD apt update
  $STD apt install -y build-essential git curl libdrm-dev libdrm-amdgpu1
  msg_ok "Updated package lists and installed build dependencies"
  
  msg_info "Installing Rust via rustup official script"
  if command -v rustc &> /dev/null; then
    msg_ok "Rust is already installed, skipping installation"
  else
    export RUSTUP_INIT_SKIP_PATH_CHECK=yes
    if [[ "$STD" == "silent" ]]; then
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1
    else
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    source $HOME/.cargo/env
    msg_ok "Installed Rust"
  fi
  
  # Ensure cargo is available
  if ! source $HOME/.cargo/env 2>/dev/null; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  
  msg_info "Cloning amdgpu_top repository"
  if [ -d "amdgpu_top" ]; then
    rm -rf amdgpu_top
  fi
  $STD git clone https://github.com/Umio-Yasuno/amdgpu_top.git
  msg_ok "Cloned amdgpu_top repository"
  
  cd amdgpu_top
  
  msg_info "Building amdgpu_top with cargo"
  $STD cargo build --release
  msg_ok "Built amdgpu_top"
  
  msg_info "Installing amdgpu_top binary to /usr/sbin"
  cp -f ./target/release/amdgpu_top /usr/sbin/
  chmod +x /usr/sbin/amdgpu_top
  msg_ok "Installed amdgpu_top binary"
  
  # Clean up build directory
  cd ..
  rm -rf amdgpu_top
  
  msg_ok "Completed Successfully!\n"
  echo -e "\n amdgpu_top has been installed and is available system-wide."
  echo -e " Run ${BL}amdgpu_top${CL} to start monitoring your AMD GPU.\n"
}

uninstall() {
  header_info
  
  if ! check_installed; then
    msg_error "amdgpu_top is not installed on this system."
    exit 1
  fi
  
  while true; do
    read -p "Are you sure you want to uninstall amdgpu_top? (y/n)? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
  
  read -r -p "Also remove Rust and build dependencies? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && REMOVE_DEPS=true || REMOVE_DEPS=false
  
  read -r -p "Verbose mode? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && STD="" || STD="silent"
  
  msg_info "Removing amdgpu_top binary"
  rm -f /usr/sbin/amdgpu_top
  msg_ok "Removed amdgpu_top binary"
  
  if [ "$REMOVE_DEPS" = true ]; then
    msg_info "Removing Rust installation"
    if [ -f "$HOME/.cargo/env" ]; then
      source $HOME/.cargo/env
      if command -v rustup &> /dev/null; then
        $STD rustup self uninstall -y
      fi
    fi
    rm -rf $HOME/.cargo $HOME/.rustup
    msg_ok "Removed Rust installation"
    
    msg_info "Removing build dependencies"
    $STD apt remove --purge -y build-essential libdrm-dev libdrm-amdgpu1
    $STD apt autoremove -y
    msg_ok "Removed build dependencies"
  fi
  
  # Clean up any leftover build directories
  rm -rf amdgpu_top
  
  msg_ok "Completed Successfully!\n"
  echo -e "\n amdgpu_top has been successfully uninstalled from your system.\n"
}

# Main execution
header_info
check_system

OPTIONS=(Install "amdgpu_top AMD GPU monitoring tool"
  Uninstall "amdgpu_top from system")

CHOICE=$(whiptail --backtitle "AMD GPU Top Installation Script" --title "amdgpu_top" \
  --menu "Select an option:" 12 65 2 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
"Install") install ;;
"Uninstall") uninstall ;;
*)
  echo "Exiting..."
  exit 0
  ;;
esac
