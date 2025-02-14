#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Arnaud Dartois (Nonobis)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"

.____     ____  ____________    ____  __.                        .___      
|    |    \   \/  /\_   ___ \  |    |/ _|____   _____   ____   __| _/____  
|    |     \     / /    \  \/  |      < /  _ \ /     \ /  _ \ / __ |/  _ \ 
|    |___  /     \ \     \____ |    |  (  <_> )  Y Y  (  <_> ) /_/ (  <_> )
|_______ \/___/\  \ \______  / |____|__ \____/|__|_|  /\____/\____ |\____/ 
        \/      \_/        \/          \/           \/            \/       

EOF
}

clear
header_info
APP="LXC Komodo Agent Installer"
hostname=$(hostname)
CRON_JOB="/etc/cron.d/komodo_agent"
LOG_FILE="/var/log/komodo_agent_install.log"
SCRIPT_URL="https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py"

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

# Ask for user confirmation before proceeding
while true; do
  read -p "This will install ${APP} on ${hostname}. Proceed? (y/n): " yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*)
    msg_error "Installation cancelled."
    exit 1
    ;;
  *) msg_error "Please answer yes or no." ;;
  esac
done

# Check Proxmox version
CURRENT_VERSION=$(pveversion)
if ! echo "$CURRENT_VERSION" | grep -Eq "pve-manager/8\.[0-9]+"; then
  msg_error "Unsupported version: $CURRENT_VERSION"
  msg_error "⚠ Requires Proxmox Virtual Environment Version 8.0 or later."
  exit 1
fi

# Fetch the list of LXC containers
msg_info "Fetching LXC container list"
vmid_list=$(pct list 2>/dev/null | awk 'NR>1 {print $1}') || { msg_error "Failed to retrieve LXC containers."; exit 1; }
if [[ -z "$vmid_list" ]]; then
  msg_error "No LXC containers found."
  exit 1
fi
msg_ok "LXC container list retrieved"

# Install Komodo Agent on each container
for vmid in $vmid_list; do
  msg_info "Installing Komodo Agent on LXC $vmid"
  
  # Securely download and install the script
  OUTPUT=$(pct exec "$vmid" -- bash -c "curl -sSL $SCRIPT_URL | python3" 2>&1)
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    msg_ok "Komodo Agent installed on LXC $vmid"

    # Enable and start the periphery service
    msg_info "Enabling periphery service on LXC $vmid"
    OUTPUT=$(pct exec "$vmid" -- systemctl enable periphery 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
      msg_ok "Periphery service enabled on LXC $vmid"
    else
      msg_error "Failed to enable periphery service on LXC $vmid"
      echo "Error enabling service on LXC $vmid:" >> "$LOG_FILE"
      echo "$OUTPUT" >> "$LOG_FILE"
    fi
  else
    msg_error "Failed to install Komodo Agent on LXC $vmid"
    echo "Installation error log for LXC $vmid:" >> "$LOG_FILE"
    echo "$OUTPUT" >> "$LOG_FILE"
  fi

  sleep 5  # Pause of 5 seconds between each installation
done

echo -e "\n${APP} installation completed successfully!"

