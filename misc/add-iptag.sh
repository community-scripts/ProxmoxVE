#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz) && Desert_Gamer
# License: MIT
# Source: https://github.com/gitsang/iptag

function header_info {
clear
cat <<"EOF"
 ___ ____     _____              
|_ _|  _ \ _ |_   _|_ _  __ _    
 | || |_) (_)  | |/ _` |/ _` |   
 | ||  __/ _   | | (_| | (_| |   
|___|_|   (_)  |_|\__,_|\__, |   
                        |___/   
EOF
}

clear
header_info
APP="IP-Tag"
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

# Check if service exists
check_service_exists() {
  if systemctl is-active --quiet iptag.service; then
    return 0
  else
    return 1
  fi
}

# Migrate configuration from old path to new
migrate_config() {
  local old_config="/opt/lxc-iptag"
  local new_config="/opt/iptag/iptag.conf"
  
  if [[ -f "$old_config" ]]; then
    msg_info "Migrating configuration from old path"
    if cp "$old_config" "$new_config" &>/dev/null; then
      rm -rf "$old_config" &>/dev/null
      msg_ok "Configuration migrated and old config removed"
    else
      msg_error "Failed to migrate configuration"
    fi
  fi
}

# Update existing installation
update_installation() {
  msg_info "Updating IP-Tag Scripts"
  systemctl stop iptag.service &>/dev/null
  
  # Migrate config if needed
  migrate_config
  
  # Update main script
  cat <<'EOF' >/opt/iptag/iptag
#!/bin/bash
# =============== CONFIGURATION =============== #
CONFIG_FILE="/opt/iptag/iptag.conf"

# Load the configuration file if it exists
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=./iptag.conf
  source "$CONFIG_FILE"
fi

# Convert IP to integer for comparison
ip_to_int() {
  local ip="$1"
  local a b c d
  IFS=. read -r a b c d <<< "${ip}"
  echo "$((a << 24 | b << 16 | c << 8 | d))"
}

# Check if IP is in CIDR
ip_in_cidr() {
  local ip="$1"
  local cidr="$2"
  local ip_int=$(ip_to_int "$ip")
  local netmask_int=$(ip_to_int "$(ipcalc -b "$cidr" | grep Broadcast | awk '{print $2}')")
  [[ $((ip_int & netmask_int)) -eq $((ip_int & netmask_int)) ]] && return 0 || return 1
}

# Check if IP is in any CIDRs
ip_in_cidrs() {
  local ip="$1"
  local cidrs=()
  mapfile -t cidrs < <(echo "$2" | tr ' ' '\n')
  for cidr in "${cidrs[@]}"; do
    ip_in_cidr "$ip" "$cidr" && return 0
  done
  return 1
}

# Check if IP is valid
is_valid_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS='.'
  read -ra parts <<< "$ip"
  for part in "${parts[@]}"; do
    [[ "$part" =~ ^[0-9]+$ ]] && ((part >= 0 && part <= 255)) || return 1
  done
  return 0
}

lxc_status_changed() {
  current_lxc_status=$(pct list 2>/dev/null)
  if [ "${last_lxc_status}" == "${current_lxc_status}" ]; then
    return 1
  else
    last_lxc_status="${current_lxc_status}"
    return 0
  fi
}

vm_status_changed() {
  current_vm_status=$(qm list 2>/dev/null)
  if [ "${last_vm_status}" == "${current_vm_status}" ]; then
    return 1
  else
    last_vm_status="${current_vm_status}"
    return 0
  fi
}

fw_net_interface_changed() {
  current_net_interface=$(ifconfig | grep "^fw")
  if [ "${last_net_interface}" == "${current_net_interface}" ]; then
    return 1
  else
    last_net_interface="${current_net_interface}"
    return 0
  fi
}

# Get VM IPs using MAC addresses and ARP table
get_vm_ips() {
  local vmid=$1
  local ips=""
  
  # Check if VM is running
  qm status "$vmid" | grep -q "status: running" || return
  
  # Get MAC addresses from VM configuration
  local macs
  macs=$(qm config "$vmid" | grep -E 'net[0-9]+' | grep -o -E '[a-fA-F0-9]{2}(:[a-fA-F0-9]{2}){5}')
  
  # Look up IPs from ARP table using MAC addresses
  for mac in $macs; do
    local ip
    ip=$(arp -an | grep -i "$mac" | grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}')
    if [ -n "$ip" ]; then
      ips+="$ip "
    fi
  done
  
  echo "$ips"
}

# Update tags for container or VM
update_tags() {
  local type="$1"
  local vmid="$2"
  local config_cmd="pct"
  [[ "$type" == "vm" ]] && config_cmd="qm"
  
  # Get current IPs
  local current_ips_full
  if [[ "$type" == "lxc" ]]; then
    current_ips_full=$(lxc-info -n "${vmid}" -i | awk '{print $2}')
  else
    current_ips_full=$(get_vm_ips "${vmid}")
  fi
  
  # Parse current tags and get valid IPs
  local current_tags=()
  local next_tags=()
  mapfile -t current_tags < <($config_cmd config "${vmid}" | grep tags | awk '{print $2}' | sed 's/;/\n/g')
  
  for tag in "${current_tags[@]}"; do
    is_valid_ipv4 "${tag}" || next_tags+=("${tag}")
  done
  
  # Add valid IPs to tags
  for ip in ${current_ips_full}; do
    is_valid_ipv4 "${ip}" && ip_in_cidrs "${ip}" "${CIDR_LIST[*]}" && next_tags+=("${ip}")
  done
  
  # Update if changed
  [[ "$(IFS=';'; echo "${current_tags[*]}")" != "$(IFS=';'; echo "${next_tags[*]}")" ]] && \
    $config_cmd set "${vmid}" -tags "$(IFS=';'; echo "${next_tags[*]}")"
}

# Check if status changed
check_status_changed() {
  local type="$1"
  local current_status
  
  case "$type" in
    "lxc")
      current_status=$(pct list 2>/dev/null)
      [[ "${last_lxc_status}" == "${current_status}" ]] && return 1
      last_lxc_status="${current_status}"
      ;;
    "vm")
      current_status=$(qm list 2>/dev/null)
      [[ "${last_vm_status}" == "${current_status}" ]] && return 1
      last_vm_status="${current_status}"
      ;;
    "fw")
      current_status=$(ifconfig | grep "^fw")
      [[ "${last_net_interface}" == "${current_status}" ]] && return 1
      last_net_interface="${current_status}"
      ;;
  esac
  return 0
}

check() {
  current_time=$(date +%s)
  
  # Check LXC status
  time_since_last_lxc_status_check=$((current_time - last_lxc_status_check_time))
  if [[ "${LXC_STATUS_CHECK_INTERVAL}" -gt 0 ]] \
    && [[ "${time_since_last_lxc_status_check}" -ge "${LXC_STATUS_CHECK_INTERVAL}" ]]; then
    echo "Checking lxc status..."
    last_lxc_status_check_time=${current_time}
    if check_status_changed "lxc"; then
      update_tags "lxc" "${vmid}"
      last_update_lxc_time=${current_time}
    fi
  fi
  
  # Check VM status
  time_since_last_vm_status_check=$((current_time - last_vm_status_check_time))
  if [[ "${VM_STATUS_CHECK_INTERVAL}" -gt 0 ]] \
    && [[ "${time_since_last_vm_status_check}" -ge "${VM_STATUS_CHECK_INTERVAL}" ]]; then
    echo "Checking vm status..."
    last_vm_status_check_time=${current_time}
    if check_status_changed "vm"; then
      update_tags "vm" "${vmid}"
      last_update_vm_time=${current_time}
    fi
  fi
  
  # Check network interface changes
  time_since_last_fw_net_interface_check=$((current_time - last_fw_net_interface_check_time))
  if [[ "${FW_NET_INTERFACE_CHECK_INTERVAL}" -gt 0 ]] \
    && [[ "${time_since_last_fw_net_interface_check}" -ge "${FW_NET_INTERFACE_CHECK_INTERVAL}" ]]; then
    echo "Checking fw net interface..."
    last_fw_net_interface_check_time=${current_time}
    if check_status_changed "fw"; then
      update_tags "lxc" "${vmid}"
      update_tags "vm" "${vmid}"
      last_update_lxc_time=${current_time}
      last_update_vm_time=${current_time}
    fi
  fi
  
  # Force update if needed
  for type in "lxc" "vm"; do
    local last_update_var="last_update_${type}_time"
    local time_since_last_update=$((current_time - ${!last_update_var}))
    if [ ${time_since_last_update} -ge ${FORCE_UPDATE_INTERVAL} ]; then
      echo "Force updating ${type} iptags..."
      case "$type" in
        "lxc") update_tags "lxc" "${vmid}" ;;
        "vm") update_tags "vm" "${vmid}" ;;
      esac
      eval "${last_update_var}=${current_time}"
    fi
  done
}

# Initialize time variables
last_lxc_status_check_time=0
last_vm_status_check_time=0
last_fw_net_interface_check_time=0
last_update_lxc_time=0
last_update_vm_time=0

# main: Set the IP tags for all LXC containers and VMs
main() {
  while true; do
    check
    sleep "${LOOP_INTERVAL}"
  done
}

main
EOF
  chmod +x /opt/iptag/iptag
  
  # Update service file
  cat <<EOF >/lib/systemd/system/iptag.service
[Unit]
Description=IP-Tag service
After=network.target

[Service]
Type=simple
ExecStart=/opt/iptag/iptag
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  
  systemctl daemon-reload &>/dev/null
  systemctl enable -q --now iptag.service &>/dev/null
  msg_ok "Updated IP-Tag Scripts"
}

# Main installation process
if check_service_exists; then
  while true; do
    read -p "IP-Tag service is already installed. Do you want to update it? (y/n): " yn
    case $yn in
      [Yy]*)
        update_installation
        exit 0
        ;;
      [Nn]*)
        msg_error "Installation cancelled."
        exit 0
        ;;
      *) msg_error "Please answer yes or no." ;;
    esac
  done
fi

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

FILE_PATH="/usr/local/bin/iptag"
if [[ -f "$FILE_PATH" ]]; then
  msg_info "The file already exists: '$FILE_PATH'. Skipping installation."
  exit 0
fi

msg_info "Installing Dependencies"
apt-get update &>/dev/null
apt-get install -y ipcalc net-tools &>/dev/null
msg_ok "Installed Dependencies"

msg_info "Setting up IP-Tag Scripts"
mkdir -p /opt/iptag
msg_ok "Setup IP-Tag Scripts"

# Migrate config if needed
migrate_config

msg_info "Setup Default Config"
if [[ ! -f /opt/iptag/iptag.conf ]]; then
  cat <<EOF >/opt/iptag/iptag.conf
# Configuration file for LXC IP tagging

# List of allowed CIDRs
CIDR_LIST=(
  192.168.0.0/16
  172.16.0.0/12
  10.0.0.0/8
  100.64.0.0/10
)

# Interval settings (in seconds)
LOOP_INTERVAL=60
VM_STATUS_CHECK_INTERVAL=60
FW_NET_INTERFACE_CHECK_INTERVAL=60
LXC_STATUS_CHECK_INTERVAL=60
FORCE_UPDATE_INTERVAL=1800
EOF
  msg_ok "Setup default config"
else
  msg_ok "Default config already exists"
fi

msg_info "Setup Main Function"
if [[ ! -f /opt/iptag/iptag ]]; then
  cat <<'EOF' >/opt/iptag/iptag
#!/bin/bash
# =============== CONFIGURATION =============== #
CONFIG_FILE="/opt/iptag/iptag.conf"

# Load the configuration file if it exists
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=./iptag.conf
  source "$CONFIG_FILE"
fi

# Convert IP to integer for comparison
ip_to_int() {
  local ip="$1"
  local a b c d
  IFS=. read -r a b c d <<< "${ip}"
  echo "$((a << 24 | b << 16 | c << 8 | d))"
}

# Check if IP is in CIDR
ip_in_cidr() {
  local ip="$1"
  local cidr="$2"
  local ip_int=$(ip_to_int "$ip")
  local netmask_int=$(ip_to_int "$(ipcalc -b "$cidr" | grep Broadcast | awk '{print $2}')")
  [[ $((ip_int & netmask_int)) -eq $((ip_int & netmask_int)) ]] && return 0 || return 1
}

# Check if IP is in any CIDRs
ip_in_cidrs() {
  local ip="$1"
  local cidrs=()
  mapfile -t cidrs < <(echo "$2" | tr ' ' '\n')
  for cidr in "${cidrs[@]}"; do
    ip_in_cidr "$ip" "$cidr" && return 0
  done
  return 1
}

# Check if IP is valid
is_valid_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS='.'
  read -ra parts <<< "$ip"
  for part in "${parts[@]}"; do
    [[ "$part" =~ ^[0-9]+$ ]] && ((part >= 0 && part <= 255)) || return 1
  done
  return 0
}

lxc_status_changed() {
  current_lxc_status=$(pct list 2>/dev/null)
  if [ "${last_lxc_status}" == "${current_lxc_status}" ]; then
    return 1
  else
    last_lxc_status="${current_lxc_status}"
    return 0
  fi
}

vm_status_changed() {
  current_vm_status=$(qm list 2>/dev/null)
  if [ "${last_vm_status}" == "${current_vm_status}" ]; then
    return 1
  else
    last_vm_status="${current_vm_status}"
    return 0
  fi
}

fw_net_interface_changed() {
  current_net_interface=$(ifconfig | grep "^fw")
  if [ "${last_net_interface}" == "${current_net_interface}" ]; then
    return 1
  else
    last_net_interface="${current_net_interface}"
    return 0
  fi
}

# Get VM IPs using MAC addresses and ARP table
get_vm_ips() {
  local vmid=$1
  local ips=""
  
  # Check if VM is running
  qm status "$vmid" | grep -q "status: running" || return
  
  # Get MAC addresses from VM configuration
  local macs
  macs=$(qm config "$vmid" | grep -E 'net[0-9]+' | grep -o -E '[a-fA-F0-9]{2}(:[a-fA-F0-9]{2}){5}')
  
  # Look up IPs from ARP table using MAC addresses
  for mac in $macs; do
    local ip
    ip=$(arp -an | grep -i "$mac" | grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}')
    if [ -n "$ip" ]; then
      ips+="$ip "
    fi
  done
  
  echo "$ips"
}

# Update tags for container or VM
update_tags() {
  local type="$1"
  local vmid="$2"
  local config_cmd="pct"
  [[ "$type" == "vm" ]] && config_cmd="qm"
  
  # Get current IPs
  local current_ips_full
  if [[ "$type" == "lxc" ]]; then
    current_ips_full=$(lxc-info -n "${vmid}" -i | awk '{print $2}')
  else
    current_ips_full=$(get_vm_ips "${vmid}")
  fi
  
  # Parse current tags and get valid IPs
  local current_tags=()
  local next_tags=()
  mapfile -t current_tags < <($config_cmd config "${vmid}" | grep tags | awk '{print $2}' | sed 's/;/\n/g')
  
  for tag in "${current_tags[@]}"; do
    is_valid_ipv4 "${tag}" || next_tags+=("${tag}")
  done
  
  # Add valid IPs to tags
  for ip in ${current_ips_full}; do
    is_valid_ipv4 "${ip}" && ip_in_cidrs "${ip}" "${CIDR_LIST[*]}" && next_tags+=("${ip}")
  done
  
  # Update if changed
  [[ "$(IFS=';'; echo "${current_tags[*]}")" != "$(IFS=';'; echo "${next_tags[*]}")" ]] && \
    $config_cmd set "${vmid}" -tags "$(IFS=';'; echo "${next_tags[*]}")"
}

check() {
  current_time=$(date +%s)
  
  # Check LXC status
  time_since_last_lxc_status_check=$((current_time - last_lxc_status_check_time))
  if [[ "${LXC_STATUS_CHECK_INTERVAL}" -gt 0 ]] \
    && [[ "${time_since_last_lxc_status_check}" -ge "${LXC_STATUS_CHECK_INTERVAL}" ]]; then
    echo "Checking lxc status..."
    last_lxc_status_check_time=${current_time}
    if check_status_changed "lxc"; then
      update_tags "lxc" "${vmid}"
      last_update_lxc_time=${current_time}
    fi
  fi
  
  # Check VM status
  time_since_last_vm_status_check=$((current_time - last_vm_status_check_time))
  if [[ "${VM_STATUS_CHECK_INTERVAL}" -gt 0 ]] \
    && [[ "${time_since_last_vm_status_check}" -ge "${VM_STATUS_CHECK_INTERVAL}" ]]; then
    echo "Checking vm status..."
    last_vm_status_check_time=${current_time}
    if check_status_changed "vm"; then
      update_tags "vm" "${vmid}"
      last_update_vm_time=${current_time}
    fi
  fi
  
  # Check network interface changes
  time_since_last_fw_net_interface_check=$((current_time - last_fw_net_interface_check_time))
  if [[ "${FW_NET_INTERFACE_CHECK_INTERVAL}" -gt 0 ]] \
    && [[ "${time_since_last_fw_net_interface_check}" -ge "${FW_NET_INTERFACE_CHECK_INTERVAL}" ]]; then
    echo "Checking fw net interface..."
    last_fw_net_interface_check_time=${current_time}
    if check_status_changed "fw"; then
      update_tags "lxc" "${vmid}"
      update_tags "vm" "${vmid}"
      last_update_lxc_time=${current_time}
      last_update_vm_time=${current_time}
    fi
  fi
  
  # Force update if needed
  for type in "lxc" "vm"; do
    local last_update_var="last_update_${type}_time"
    local time_since_last_update=$((current_time - ${!last_update_var}))
    if [ ${time_since_last_update} -ge ${FORCE_UPDATE_INTERVAL} ]; then
      echo "Force updating ${type} iptags..."
      case "$type" in
        "lxc") update_tags "lxc" "${vmid}" ;;
        "vm") update_tags "vm" "${vmid}" ;;
      esac
      eval "${last_update_var}=${current_time}"
    fi
  done
}

# Initialize time variables
last_lxc_status_check_time=0
last_vm_status_check_time=0
last_fw_net_interface_check_time=0
last_update_lxc_time=0
last_update_vm_time=0

# main: Set the IP tags for all LXC containers and VMs
main() {
  while true; do
    check
    sleep "${LOOP_INTERVAL}"
  done
}

main
EOF
  msg_ok "Setup Main Function"
else
  msg_ok "Main Function already exists"
fi
chmod +x /opt/iptag/iptag

msg_info "Creating Service"
if [[ ! -f /lib/systemd/system/iptag.service ]]; then
  cat <<EOF >/lib/systemd/system/iptag.service
[Unit]
Description=IP-Tag service
After=network.target

[Service]
Type=simple
ExecStart=/opt/iptag/iptag
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  msg_ok "Created Service"
else
  msg_ok "Service already exists."
fi

msg_ok "Setup IP-Tag Scripts"

msg_info "Starting Service"
systemctl daemon-reload &>/dev/null
systemctl enable -q --now iptag.service &>/dev/null
msg_ok "Started Service"
SPINNER_PID=""
echo -e "\n${APP} installation completed successfully! ${CL}\n"
