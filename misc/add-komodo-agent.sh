#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gitsang/lxc-iptag

function header_info {
clear
cat <<"EOF"
    __   _  ________   ________      ______           
   / /  | |/ / ____/  /  _/ __ \    /_  __/___ _____ _  
  / /   |   / /       / // /_/ /_____/ / / __ `/ __ `/  
 / /___/   / /___   _/ // ____/_____/ / / /_/ / /_/ /  
/_____/_/|_\____/  /___/_/         /_/  \__,_/\__, /  
                                             /____/   
EOF
}

clear
header_info
APP="LXC Agent Installer"
hostname=$(hostname)

# Farbvariablen
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD=" "
CM=" ✔️ ${CL}"
CROSS=" ✖️ ${CL}"

# This function enables error handling in the script by setting options and defining a trap for the ERR signal.
catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

# This function is called when an error occurs. It receives the exit code, line number, and command that caused the error, and displays an error message.
error_handler() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID >/dev/null; then kill $SPINNER_PID >/dev/null; fi
  printf "\e[?25h"
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
}

# This function displays a spinner.
spinner() {
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local spin_i=0
  local interval=0.1
  printf "\e[?25l"

  local color="${YWB}"

  while true; do
  printf "\r ${color}%s${CL}" "${frames[spin_i]}"
  spin_i=$(((spin_i + 1) % ${#frames[@]}))
  sleep "$interval"
  done
}

# This function displays an informational message with a yellow color.
msg_info() {
  local msg="$1"
  echo -ne "${TAB}${YW}${HOLD}${msg}${HOLD}"
  spinner & 
  SPINNER_PID=$!
}

# This function displays a success message with a green color.
msg_ok() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID >/dev/null; then kill $SPINNER_PID >/dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${CM}${GN}${msg}${CL}"
}

# This function displays a error message with a red color.
msg_error() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID >/dev/null; then kill $SPINNER_PID >/dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${CROSS}${RD}${msg}${CL}"
}

while true; do
  read -p "This will install ${APP} on ${hostname}. Proceed? (y/n): " yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*)
  msg_error "Installation cancelled."
  exit
  ;;
  *) msg_error "Please answer yes or no." ;;
  esac
done

if ! pveversion | grep -Eq "pve-manager/8\.[0-3](\.[0-9]+)*"; then
  msg_error "This version of Proxmox Virtual Environment is not supported"
  msg_error "⚠️ Requires Proxmox Virtual Environment Version 8.0 or later."
  msg_error "Exiting..."
  sleep 2
  exit
fi

FILE_PATH="/usr/local/bin/lxc-agent-installer"
if [[ -f "$FILE_PATH" ]]; then
  msg_info "The script already exists: '$FILE_PATH'. Skipping installation."
  exit 0
fi

msg_info "Setting up Agent Installer Scripts"
mkdir -p /opt/lxc-agent-installer
msg_ok "Setup Agent Installer Scripts"

msg_info "Creating LXC Agent Installation Script"
cat <<'EOF' >/opt/lxc-agent-installer/lxc-agent-installer.sh
#!/bin/bash

# ========================= INSTALL AGENT ======================== #

install_agent() {
  curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3
}

# ===================== MAIN FUNCTION ============================ #

install_agent_on_all_lxcs() {
  vmid_list=$(pct list 2>/dev/null | grep -v VMID | awk '{print $1}')
  for vmid in ${vmid_list}; do
    echo "Installing agent on LXC ${vmid}..."
    pct exec "${vmid}" -- /opt/lxc-agent-installer/lxc-agent-installer.sh
  done
}

install_agent_on_all_lxcs
EOF

msg_ok "Created Agent Installer Script"

msg_info "Making Script Executable"
chmod +x /opt/lxc-agent-installer/lxc-agent-installer.sh
msg_ok "Script is now executable"

msg_info "Creating Systemd Service"
if [[ ! -f /lib/systemd/system/lxc-agent-installer.service ]]; then
  cat <<EOF >/lib/systemd/system/lxc-agent-installer.service
[Unit]
Description=LXC Agent Installer service
After=network.target

[Service]
Type=simple
ExecStart=/opt/lxc-agent-installer/lxc-agent-installer.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  msg_ok "Created Systemd Service"
else
  msg_ok "Service already exists."
fi

msg_info "Starting Service"
systemctl daemon-reload &>/dev/null
systemctl enable -q --now lxc-agent-installer.service &>/dev/null
msg_ok "Started Service"

SPINNER_PID=""
echo -e "\n${APP} installation completed successfully! ${CL}\n"
