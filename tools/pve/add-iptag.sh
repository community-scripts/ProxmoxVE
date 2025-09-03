#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz) && Desert_Gamer
# License: MIT

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

# Color variables
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD=" "
CM="${GN}✓${CL} "
CROSS="${RD}✗${CL} "

# Stop any running spinner
stop_spinner() {
  if [ -n "$SPINNER_PID" ] && kill -0 "$SPINNER_PID" 2>/dev/null; then
    kill -TERM "$SPINNER_PID" 2>/dev/null
    wait "$SPINNER_PID" 2>/dev/null
  fi
  SPINNER_PID=""
  printf "\e[?25h\r"
}

# Error handler for displaying error messages
error_handler() {
  stop_spinner
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
}

# Spinner for progress indication
spinner() {
  local msg="$1"
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local spin_i=0
  local interval=0.1
  
  trap 'exit 0' TERM INT
  printf "\e[?25l" 2>/dev/null

  while true; do
    printf "\r%s ${YW}%s${CL}" "${frames[spin_i]}" "$msg" 2>/dev/null || exit 0
    spin_i=$(((spin_i + 1) % ${#frames[@]}))
    sleep "$interval" || exit 0
  done
}

# Info message
msg_info() {
  local msg="$1"
  stop_spinner
  spinner "$msg" &
  SPINNER_PID=$!
  disown $SPINNER_PID 2>/dev/null
}

# Success message
msg_ok() {
  stop_spinner
  local msg="$1"
  echo -e "${BFR}${CM}${GN}${msg}${CL}"
}

# Error message
msg_error() {
  stop_spinner
  local msg="$1"
  echo -e "${BFR}${CROSS}${RD}${msg}${CL}"
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
  msg_ok "Stopped IP-Tag service"

  # Create directory if it doesn't exist
  if [[ ! -d "/opt/iptag" ]]; then
    mkdir -p /opt/iptag
  fi

  # Create new config file (check if exists and ask user)
  if [[ -f "/opt/iptag/iptag.conf" ]]; then
    echo -e "\n${YW}Configuration file already exists.${CL}"
    echo -e "${YW}Note: No critical changes were made in this version.${CL}"
    while true; do
      read -p "Do you want to replace it with defaults? (y/n): " yn
      case $yn in
      [Yy]*)
        interactive_config_setup
        msg_info "Replacing configuration file"
        generate_config >/opt/iptag/iptag.conf
        msg_ok "Configuration file replaced with defaults"
        break
        ;;
      [Nn]*)
        echo -e "${GN}✓ Keeping existing configuration file${CL}"
        break
        ;;
      *)
        echo -e "${RD}Please answer yes or no.${CL}"
        ;;
      esac
    done
  else
    interactive_config_setup
    msg_info "Creating new configuration file"
    generate_config >/opt/iptag/iptag.conf
    msg_ok "Created new configuration file at /opt/iptag/iptag.conf"
  fi

  # Update main script
  msg_info "Updating main script"
  generate_main_script >/opt/iptag/iptag
  chmod +x /opt/iptag/iptag
  msg_ok "Updated main script"

  # Update service file
  msg_info "Updating service file"
  generate_service >/lib/systemd/system/iptag.service
  msg_ok "Updated service file"

  msg_info "Creating manual run command"
  cat <<'EOF' >/usr/local/bin/iptag-run
#!/usr/bin/env bash
CONFIG_FILE="/opt/iptag/iptag.conf"
SCRIPT_FILE="/opt/iptag/iptag"
if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo "✗ Main script not found: $SCRIPT_FILE"
  exit 1
fi
export FORCE_SINGLE_RUN=true
exec "$SCRIPT_FILE"
EOF
  chmod +x /usr/local/bin/iptag-run
  msg_ok "Created iptag-run executable - You can execute this manually by entering “iptag-run” in the Proxmox host, so the script is executed by hand."

  msg_info "Restarting service"
  systemctl daemon-reload &>/dev/null
  systemctl enable -q --now iptag.service &>/dev/null
  msg_ok "Updated IP-Tag Scripts"
  
  # Show configuration information after update
  show_post_install_info
}

# Install only command without service
install_command_only() {
  msg_info "Installing IP-Tag Command Only"
  
  # Create directory if it doesn't exist
  if [[ ! -d "/opt/iptag" ]]; then
    mkdir -p /opt/iptag
  fi

  # Migrate config if needed
  migrate_config

  # Interactive configuration setup
  if [[ ! -f /opt/iptag/iptag.conf ]]; then
    interactive_config_setup_command
    msg_info "Setup Configuration"
    generate_config >/opt/iptag/iptag.conf
    msg_ok "Created configuration file at /opt/iptag/iptag.conf"
  else
    stop_spinner
    echo -e "\n${YW}Configuration file already exists.${CL}"
    read -p "Do you want to reconfigure tag format? (y/n): " reconfigure
    case $reconfigure in
      [Yy]*)
        interactive_config_setup_command
        msg_info "Updating Configuration"
        generate_config >/opt/iptag/iptag.conf
        msg_ok "Updated configuration file"
        ;;
      *)
        msg_ok "Keeping existing configuration file"
        ;;
    esac
  fi

  # Setup main script
  msg_info "Setup Main Script"
  generate_main_script >/opt/iptag/iptag
  chmod +x /opt/iptag/iptag
  msg_ok "Created main script"

  # Create manual run command
  msg_info "Creating iptag-run command"
  cat <<'EOF' >/usr/local/bin/iptag-run
#!/usr/bin/env bash
CONFIG_FILE="/opt/iptag/iptag.conf"
SCRIPT_FILE="/opt/iptag/iptag"
if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo "✗ Main script not found: $SCRIPT_FILE"
  exit 1
fi
export FORCE_SINGLE_RUN=true
exec "$SCRIPT_FILE"
EOF
  chmod +x /usr/local/bin/iptag-run
  msg_ok "Created iptag-run command"
  
  msg_ok "IP-Tag Command installed successfully! Use 'iptag-run' to run manually."
}

# Show post-installation information
show_post_install_info() {
  stop_spinner
  echo -e "\n${YW}=== Next Steps ===${CL}"
  
  # Show usage information
  if command -v iptag-run >/dev/null 2>&1; then
    echo -e "${YW}Run IP tagging manually: ${GN}iptag-run${CL}"
    echo -e "${YW}Add to cron for scheduled execution if needed${CL}"
    echo -e ""
  fi
  
  echo -e "${RD}IMPORTANT: Configure your network subnets!${CL}"
  echo -e ""
  echo -e "${YW}Configuration file: ${GN}/opt/iptag/iptag.conf${CL}"
  echo -e ""
  echo -e "${YW}Edit CIDR_LIST with your actual subnets:${CL}"
  echo -e "${GN}nano /opt/iptag/iptag.conf${CL} ${YW}or${CL} ${GN}vim /opt/iptag/iptag.conf${CL}"
  echo -e ""
  echo -e "${YW}Example configuration:${CL}"
  echo -e "${GN}CIDR_LIST=(${CL}"
  echo -e "${GN}  192.168.1.0/24    # Your actual subnet${CL}"
  echo -e "${GN}  10.10.0.0/16      # Another subnet${CL}"
  echo -e "${GN})${CL}"
  echo -e ""
}

# Interactive configuration setup for command-only (TAG_FORMAT only)
interactive_config_setup_command() {
  echo -e "\n${YW}=== Configuration Setup ===${CL}"
  
  # TAG_FORMAT configuration
  echo -e "\n${YW}Select tag format:${CL}"
  echo -e "${GN}1)${CL} last_two_octets - Show last two octets (e.g., 0.100) [Default]"
  echo -e "${GN}2)${CL} last_octet - Show only last octet (e.g., 100)"
  echo -e "${GN}3)${CL} full - Show full IP address (e.g., 192.168.0.100)"
  
  while true; do
    read -p "Enter your choice (1-3) [1]: " tag_choice
    case ${tag_choice:-1} in
      1)
        TAG_FORMAT="last_two_octets"
        echo -e "${GN}✓ Selected: last_two_octets${CL}"
        break
        ;;
      2)
        TAG_FORMAT="last_octet"
        echo -e "${GN}✓ Selected: last_octet${CL}"
        break
        ;;
      3)
        TAG_FORMAT="full"
        echo -e "${GN}✓ Selected: full${CL}"
        break
        ;;
      *)
        echo -e "${RD}Please enter 1, 2, or 3.${CL}"
        ;;
    esac
  done
  
  # Set default LOOP_INTERVAL for command mode
  LOOP_INTERVAL=300
}

# Interactive configuration setup for service (TAG_FORMAT + LOOP_INTERVAL)
interactive_config_setup() {
  echo -e "\n${YW}=== Configuration Setup ===${CL}"
  
  # TAG_FORMAT configuration
  echo -e "\n${YW}Select tag format:${CL}"
  echo -e "${GN}1)${CL} last_two_octets - Show last two octets (e.g., 0.100) [Default]"
  echo -e "${GN}2)${CL} last_octet - Show only last octet (e.g., 100)"
  echo -e "${GN}3)${CL} full - Show full IP address (e.g., 192.168.0.100)"
  
  while true; do
    read -p "Enter your choice (1-3) [1]: " tag_choice
    case ${tag_choice:-1} in
      1)
        TAG_FORMAT="last_two_octets"
        echo -e "${GN}✓ Selected: last_two_octets${CL}"
        break
        ;;
      2)
        TAG_FORMAT="last_octet"
        echo -e "${GN}✓ Selected: last_octet${CL}"
        break
        ;;
      3)
        TAG_FORMAT="full"
        echo -e "${GN}✓ Selected: full${CL}"
        break
        ;;
      *)
        echo -e "${RD}Please enter 1, 2, or 3.${CL}"
        ;;
    esac
  done
  
  # LOOP_INTERVAL configuration
  echo -e "\n${YW}Set check interval (in seconds):${CL}"
  echo -e "${YW}Default: 300 seconds (5 minutes)${CL}"
  echo -e "${YW}Recommended range: 300-3600 seconds${CL}"
  
  while true; do
    read -p "Enter interval in seconds [300]: " interval_input
    interval_input=${interval_input:-300}
    
    if [[ $interval_input =~ ^[0-9]+$ ]] && [ $interval_input -ge 300 ] && [ $interval_input -le 7200 ]; then
      LOOP_INTERVAL=$interval_input
      echo -e "${GN}✓ Selected: ${LOOP_INTERVAL} seconds${CL}"
      break
    else
      echo -e "${RD}Please enter a valid number between 300 and 7200 seconds.${CL}"
    fi
  done
}

# Generate configuration file content
generate_config() {
  cat <<EOF
# Configuration file for IP tagging

# List of allowed CIDRs
CIDR_LIST=(
  192.168.0.0/16
  10.0.0.0/8
  100.64.0.0/10
)

# Tag format options:
# - "full": full IP address (e.g., 192.168.0.100)
# - "last_octet": only the last octet (e.g., 100)
# - "last_two_octets": last two octets (e.g., 0.100)
TAG_FORMAT="${TAG_FORMAT:-last_two_octets}"


# Check interval (in seconds)
LOOP_INTERVAL=${LOOP_INTERVAL:-300}

# Debug settings (set to true to enable debugging)
DEBUG=false
EOF
}

# Generate systemd service file content
generate_service() {
  cat <<EOF
[Unit]
Description=IP-Tag service
After=network.target

[Service]
Type=simple
ExecStart=/opt/iptag/iptag
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
}

# Generate main script content
generate_main_script() {
  cat <<'EOF'
#!/bin/bash
# =============== CONFIGURATION =============== #
readonly CONFIG_FILE="/opt/iptag/iptag.conf"
readonly DEFAULT_TAG_FORMAT="full"
readonly DEFAULT_CHECK_INTERVAL=60

# Load the configuration file if it exists
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=./iptag.conf
    source "$CONFIG_FILE"
fi

# Set default DEBUG value if not defined
DEBUG=${DEBUG:-false}

# Debug logging function
debug_log() {
    if [[ "$DEBUG" == "true" || "$DEBUG" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Color constants
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m' # No Color

# Logging functions with colors
log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_change() {
    echo -e "${CYAN}~${NC} $*"
}

log_unchanged() {
    echo -e "${GRAY}=${NC} $*"
}

# Check if IP is in CIDR
ip_in_cidr() {
    local ip="$1" cidr="$2"
    debug_log "ip_in_cidr: checking '$ip' against '$cidr'"
    
    # Manual CIDR check - более надёжный метод
    debug_log "ip_in_cidr: using manual check (bypassing ipcalc)"
        local network prefix
        IFS='/' read -r network prefix <<< "$cidr"
        
        # Convert IP and network to integers for comparison
        local ip_int net_int mask
        IFS='.' read -r a b c d <<< "$ip"
        ip_int=$(( (a << 24) + (b << 16) + (c << 8) + d ))
        
        IFS='.' read -r a b c d <<< "$network"
        net_int=$(( (a << 24) + (b << 16) + (c << 8) + d ))
        
    # Create subnet mask
        mask=$(( 0xFFFFFFFF << (32 - prefix) ))
        
    # Apply mask and compare
    local ip_masked=$((ip_int & mask))
    local net_masked=$((net_int & mask))
    
    debug_log "ip_in_cidr: IP=$ip ($ip_int), Network=$network ($net_int), Prefix=$prefix"
    debug_log "ip_in_cidr: Mask=$mask (hex: $(printf '0x%08x' $mask))"
    debug_log "ip_in_cidr: IP&Mask=$ip_masked ($(printf '%d.%d.%d.%d' $((ip_masked>>24&255)) $((ip_masked>>16&255)) $((ip_masked>>8&255)) $((ip_masked&255))))"
    debug_log "ip_in_cidr: Net&Mask=$net_masked ($(printf '%d.%d.%d.%d' $((net_masked>>24&255)) $((net_masked>>16&255)) $((net_masked>>8&255)) $((net_masked&255))))"
    
    if (( ip_masked == net_masked )); then
        debug_log "ip_in_cidr: manual check PASSED - IP is in CIDR"
        return 0
    else
        debug_log "ip_in_cidr: manual check FAILED - IP is NOT in CIDR"
        return 1
    fi
}

# Format IP address according to the configuration
format_ip_tag() {
    local ip="$1"
    [[ -z "$ip" ]] && return
    local format="${TAG_FORMAT:-$DEFAULT_TAG_FORMAT}"
    case "$format" in
        "last_octet")     echo "${ip##*.}" ;;
        "last_two_octets") echo "${ip#*.*.}" ;;
        *)               echo "$ip" ;;
    esac
}


# Check if IP is in any CIDRs
ip_in_cidrs() {
    local ip="$1" cidrs="$2"
    [[ -z "$cidrs" ]] && return 1
    local IFS=' '
    debug_log "Checking IP '$ip' against CIDRs: '$cidrs'"
    for cidr in $cidrs; do 
        debug_log "Testing IP '$ip' against CIDR '$cidr'"
        if ip_in_cidr "$ip" "$cidr"; then
            debug_log "IP '$ip' matches CIDR '$cidr' - PASSED"
            return 0
        else
            debug_log "IP '$ip' does not match CIDR '$cidr'"
        fi
    done
    debug_log "IP '$ip' failed all CIDR checks"
    return 1
}

# Check if IP is valid
is_valid_ipv4() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    
    local IFS='.' parts
    read -ra parts <<< "$ip"
    for part in "${parts[@]}"; do
        (( part >= 0 && part <= 255 )) || return 1
    done
    return 0
}

# Get VM IPs using improved methods
get_vm_ips() {
    local vmid=$1 ips=""
    local vm_config="/etc/pve/qemu-server/${vmid}.conf"
    [[ ! -f "$vm_config" ]] && return
    
    debug_log "vm $vmid: starting IP detection"
    
    # Check if VM is running first
    local vm_status=""
    if command -v qm >/dev/null 2>&1; then
        vm_status=$(qm status "$vmid" 2>/dev/null | awk '{print $2}')
    fi
    
    if [[ "$vm_status" != "running" ]]; then
        debug_log "vm $vmid: not running (status: $vm_status)"
        return
    fi
    
    # Get MAC addresses from config
    local mac_addresses=$(grep -E "^net[0-9]+:" "$vm_config" | grep -oE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}" | head -3)
    debug_log "vm $vmid: found MACs: $mac_addresses"
    
    # Method 1: QM guest agent (most reliable for current IP)
    if command -v qm >/dev/null 2>&1; then
        debug_log "vm $vmid: trying qm guest agent first"
        local qm_ips=$(timeout 8 qm guest cmd "$vmid" network-get-interfaces 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v "127.0.0.1" | head -3)
        for qm_ip in $qm_ips; do
            if [[ "$qm_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                debug_log "vm $vmid: found IP $qm_ip via qm guest cmd"
                ips+="$qm_ip "
            fi
        done
    fi
    
    # Method 2: Fresh ARP table lookup (force refresh)
    if [[ -n "$mac_addresses" ]]; then
        debug_log "vm $vmid: refreshing ARP table and checking"
        # Try to refresh ARP table by pinging network ranges
        for mac in $mac_addresses; do
            local mac_lower=$(echo "$mac" | tr '[:upper:]' '[:lower:]')
            
            # First check current ARP table
            local current_ip=$(ip neighbor show | grep "$mac_lower" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
            
            # If found in ARP, verify it's still valid by trying to ping
            if [[ -n "$current_ip" && "$current_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                debug_log "vm $vmid: found IP $current_ip in ARP table for MAC $mac_lower, verifying..."
                # Quick ping test to verify IP is still active
                if timeout 2 ping -c 1 "$current_ip" >/dev/null 2>&1; then
                    debug_log "vm $vmid: verified IP $current_ip is active via ping"
                    ips+="$current_ip "
                else
                    debug_log "vm $vmid: IP $current_ip failed ping verification, removing from ARP"
                    # Remove stale ARP entry
                    ip neighbor del "$current_ip" dev $(ip route get "$current_ip" 2>/dev/null | grep -oE 'dev [^ ]+' | cut -d' ' -f2) 2>/dev/null || true
                fi
            fi
        done
    fi
    
    # Method 3: DHCP leases (backup method)
    if [[ -z "$ips" ]]; then
        debug_log "vm $vmid: checking DHCP leases as fallback"
        for mac in $mac_addresses; do
            local mac_lower=$(echo "$mac" | tr '[:upper:]' '[:lower:]')
            for dhcp_file in "/var/lib/dhcp/dhcpd.leases" "/var/lib/dhcpcd5/dhcpcd.leases"; do
                if [[ -f "$dhcp_file" ]]; then
                    # Look for most recent lease for this MAC
                    local dhcp_ip=$(tac "$dhcp_file" 2>/dev/null | grep -A 10 "ethernet $mac_lower" | grep "binding state active" -A 5 | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -1)
                    if [[ -n "$dhcp_ip" && "$dhcp_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                        debug_log "vm $vmid: found IP $dhcp_ip via DHCP leases"
                        # Verify this IP responds
                        if timeout 2 ping -c 1 "$dhcp_ip" >/dev/null 2>&1; then
                            debug_log "vm $vmid: verified DHCP IP $dhcp_ip is active"
                            ips+="$dhcp_ip "
                            break 2
                        else
                            debug_log "vm $vmid: DHCP IP $dhcp_ip failed ping test"
                        fi
                    fi
                fi
            done
        done
    fi
    
    # Remove duplicates and clean up
    local unique_ips=$(echo "$ips" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    unique_ips="${unique_ips% }"
    
    debug_log "vm $vmid: final IPs: '$unique_ips'"
    echo "$unique_ips"
}

# Update tags for container or VM
update_tags() {
    local type="$1" vmid="$2"
    local current_ips_full

    if [[ "$type" == "lxc" ]]; then
        current_ips_full=$(get_lxc_ips "${vmid}")
        while IFS= read -r line; do
          [[ "$line" == tags:* ]] && current_tags_raw="${line#tags: }" && break
        done < <(pct config "$vmid" 2>/dev/null)
    else
        current_ips_full=$(get_vm_ips "${vmid}")
        local vm_config="/etc/pve/qemu-server/${vmid}.conf"
        if [[ -f "$vm_config" ]]; then
            local current_tags_raw=$(grep "^tags:" "$vm_config" 2>/dev/null | cut -d: -f2 | sed 's/^[[:space:]]*//')
        fi
    fi

    local current_tags=() next_tags=() current_ip_tags=()
    if [[ -n "$current_tags_raw" ]]; then
        mapfile -t current_tags < <(echo "$current_tags_raw" | sed 's/;/\n/g')
    fi

    # Separate IP/numeric and user tags
    for tag in "${current_tags[@]}"; do
        if is_valid_ipv4 "${tag}" || [[ "$tag" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
            current_ip_tags+=("${tag}")
        else
            next_tags+=("${tag}")
        fi
    done

    # Generate new IP tags from current IPs
    local formatted_ips=()
    debug_log "$type $vmid current_ips_full: '$current_ips_full'"
    debug_log "$type $vmid CIDR_LIST: ${CIDR_LIST[*]}"
    for ip in $current_ips_full; do
        [[ -z "$ip" ]] && continue
        debug_log "$type $vmid processing IP: '$ip'"
        if is_valid_ipv4 "$ip"; then
            debug_log "$type $vmid IP '$ip' is valid"
            if ip_in_cidrs "$ip" "${CIDR_LIST[*]}"; then
                debug_log "$type $vmid IP '$ip' passed CIDR check"
                local formatted_ip=$(format_ip_tag "$ip")
                debug_log "$type $vmid formatted '$ip' -> '$formatted_ip'"
                [[ -n "$formatted_ip" ]] && formatted_ips+=("$formatted_ip")
            else
                debug_log "$type $vmid IP '$ip' failed CIDR check"
            fi
        else
            debug_log "$type $vmid IP '$ip' is invalid"
        fi
    done
    debug_log "$type $vmid final formatted_ips: ${formatted_ips[*]}"

    # If LXC and no IPs detected, do not touch tags at all
    if [[ "$type" == "lxc" && ${#formatted_ips[@]} -eq 0 ]]; then
        log_unchanged "LXC ${GRAY}${vmid}${NC}: No IP detected, tags unchanged"
        return
    fi

    # Prepend new IP tags to the beginning of the tag list
    local final_tags=()
    for new_ip in "${formatted_ips[@]}"; do
        final_tags+=("$new_ip")
    done
    for tag in "${next_tags[@]}"; do
        final_tags+=("$tag")
    done
    next_tags=("${final_tags[@]}")

    # Update tags if there are changes
    local old_tags_str=$(IFS=';'; echo "${current_tags[*]}")
    local new_tags_str=$(IFS=';'; echo "${next_tags[*]}")
    
    debug_log "$type $vmid old_tags: '$old_tags_str'"
    debug_log "$type $vmid new_tags: '$new_tags_str'"
    debug_log "$type $vmid tags_equal: $([[ "$old_tags_str" == "$new_tags_str" ]] && echo true || echo false)"
    
    if [[ "$old_tags_str" != "$new_tags_str" ]]; then
        # Determine what changed
        local old_ip_tags_count=${#current_ip_tags[@]}
        local new_ip_tags_count=${#formatted_ips[@]}
        
        # Build detailed change message
        local change_details=""
        
        if [[ $old_ip_tags_count -eq 0 ]]; then
            change_details="added ${new_ip_tags_count} IP tag(s): [${GREEN}${formatted_ips[*]}${NC}]"
        else
            # Compare old and new IP tags
            local added_tags=() removed_tags=() common_tags=()
            
            # Find removed tags
            for old_tag in "${current_ip_tags[@]}"; do
                local found=false
                for new_tag in "${formatted_ips[@]}"; do
                    if [[ "$old_tag" == "$new_tag" ]]; then
                        found=true
                        break
                    fi
                done
                if [[ "$found" == false ]]; then
                    removed_tags+=("$old_tag")
                else
                    common_tags+=("$old_tag")
                fi
            done
            
            # Find added tags
            for new_tag in "${formatted_ips[@]}"; do
                local found=false
                for old_tag in "${current_ip_tags[@]}"; do
                    if [[ "$new_tag" == "$old_tag" ]]; then
                        found=true
                        break
                    fi
                done
                if [[ "$found" == false ]]; then
                    added_tags+=("$new_tag")
                fi
            done
            
            # Build change message
            local change_parts=()
            if [[ ${#added_tags[@]} -gt 0 ]]; then
                change_parts+=("added [${GREEN}${added_tags[*]}${NC}]")
            fi
            if [[ ${#removed_tags[@]} -gt 0 ]]; then
                change_parts+=("removed [${YELLOW}${removed_tags[*]}${NC}]")
            fi
            if [[ ${#common_tags[@]} -gt 0 ]]; then
                change_parts+=("kept [${GRAY}${common_tags[*]}${NC}]")
            fi
            
            change_details=$(IFS=', '; echo "${change_parts[*]}")
        fi
        
        log_change "${type^^} ${CYAN}${vmid}${NC}: ${change_details}"
        
        if [[ "$type" == "lxc" ]]; then
            pct set "${vmid}" -tags "$(IFS=';'; echo "${next_tags[*]}")" &>/dev/null
        else
            local vm_config="/etc/pve/qemu-server/${vmid}.conf"
            if [[ -f "$vm_config" ]]; then
                sed -i '/^tags:/d' "$vm_config"
                if [[ ${#next_tags[@]} -gt 0 ]]; then
                    echo "tags: $(IFS=';'; echo "${next_tags[*]}")" >> "$vm_config"
                fi
            fi
        fi
    else
        # Tags unchanged
        local ip_count=${#formatted_ips[@]}
        local status_msg=""
        
        if [[ $ip_count -eq 0 ]]; then
            status_msg="No IPs detected"
        elif [[ $ip_count -eq 1 ]]; then
            status_msg="IP tag [${GRAY}${formatted_ips[0]}${NC}] unchanged"
        else
            status_msg="${ip_count} IP tags [${GRAY}${formatted_ips[*]}${NC}] unchanged"
        fi
        
        log_unchanged "${type^^} ${GRAY}${vmid}${NC}: ${status_msg}"
    fi
}

# Update all instances of specified type
update_all_tags() {
    local type="$1" vmids count=0
    
    if [[ "$type" == "lxc" ]]; then
        vmids=($(pct list 2>/dev/null | grep -v VMID | awk '{print $1}'))
    else
        local all_vm_configs=($(ls /etc/pve/qemu-server/*.conf 2>/dev/null | sed 's/.*\/\([0-9]*\)\.conf/\1/' | sort -n))
        vmids=("${all_vm_configs[@]}")
    fi
    
    count=${#vmids[@]}
    [[ $count -eq 0 ]] && return
    
    # Display processing header with color
    if [[ "$type" == "lxc" ]]; then
        log_info "Processing ${WHITE}${count}${NC} LXC container(s) sequentially"
    else
        log_info "Processing ${WHITE}${count}${NC} virtual machine(s) sequentially"
    fi
    
    # Process each VM/LXC container sequentially
    for vmid in "${vmids[@]}"; do
        update_tags "$type" "$vmid"
    done
    
    # Add completion message
    if [[ "$type" == "lxc" ]]; then
        log_success "Completed processing LXC containers"
    else
        log_success "Completed processing virtual machines"
    fi
}

# Check if status changed
check_status_changed() {
    local type="$1" current
    case "$type" in
        "lxc") current=$(pct list 2>/dev/null | grep -v VMID) ;;
        "vm")  current=$(ls -la /etc/pve/qemu-server/*.conf 2>/dev/null) ;;
        "fw")  current=$(ip link show type bridge 2>/dev/null) ;;
    esac
    local last_var="last_${type}_status"
    [[ "${!last_var}" == "$current" ]] && return 1
    eval "$last_var='$current'"
    return 0
}

# Main check function
check() {
    local current_time=$(date +%s)
    
    # Simple periodic check - always update both LXC and VM every loop
    log_info "Starting periodic check"
    
    # Update LXC containers
    update_all_tags "lxc"
    
    # Update VMs  
    update_all_tags "vm"
}

# Main loop
main() {
    # Display startup message
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_success "IP-Tag service started successfully"
    echo -e "${BLUE}ℹ${NC} Loop interval: ${WHITE}${LOOP_INTERVAL:-300}${NC} seconds"
    echo -e "${BLUE}ℹ${NC} Debug mode: ${WHITE}${DEBUG:-false}${NC}"
    echo -e "${BLUE}ℹ${NC} Tag format: ${WHITE}${TAG_FORMAT:-full}${NC}"
    echo -e "${BLUE}ℹ${NC} Allowed CIDRs: ${WHITE}${CIDR_LIST[*]}${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    if [[ "$FORCE_SINGLE_RUN" == "true" ]]; then
        check
        exit 0
    fi

    while true; do
        check
        sleep "${LOOP_INTERVAL:-300}"
    done
}





# Simple LXC IP detection
get_lxc_ips() {
    local vmid=$1
    
    debug_log "lxc $vmid: starting IP detection"
    
    # Check if LXC is running
    local lxc_status=$(pct status "${vmid}" 2>/dev/null | awk '{print $2}')
    if [[ "$lxc_status" != "running" ]]; then
        debug_log "lxc $vmid: not running (status: $lxc_status)"
        return
    fi
    
    local ips=""
    
    # Method 1: Check Proxmox config for static IP
    local pve_lxc_config="/etc/pve/lxc/${vmid}.conf"
    if [[ -f "$pve_lxc_config" ]]; then
        local static_ip=$(grep -E "^net[0-9]+:" "$pve_lxc_config" 2>/dev/null | grep -oE 'ip=([0-9]{1,3}\.){3}[0-9]{1,3}' | cut -d'=' -f2 | head -1)
        if [[ -n "$static_ip" && "$static_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            debug_log "lxc $vmid: found static IP $static_ip in config"
            ips="$static_ip"
        fi
    fi
    
    # Method 2: ARP table lookup if no static IP
    if [[ -z "$ips" && -f "$pve_lxc_config" ]]; then
        local mac_addr=$(grep -Eo 'hwaddr=([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' "$pve_lxc_config" | head -1 | cut -d'=' -f2)
        if [[ -n "$mac_addr" ]]; then
            local bridge_name=$(grep -Eo 'bridge=[^,]+' "$pve_lxc_config" | head -1 | cut -d'=' -f2)
            local arp_ip=$(ip neighbor show | grep "$mac_addr" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
            if [[ -n "$arp_ip" && "$arp_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                debug_log "lxc $vmid: found IP $arp_ip via ARP table"
                ips="$arp_ip"
            fi
        fi
    fi
    
    # Method 3: Direct container command if ARP failed
    if [[ -z "$ips" ]]; then
        local container_ip=$(timeout 5s pct exec "$vmid" -- ip -4 addr show 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1)
        if [[ -n "$container_ip" ]] && is_valid_ipv4 "$container_ip"; then
            debug_log "lxc $vmid: found IP $container_ip via pct exec"
            ips="$container_ip"
        fi
    fi
    
    debug_log "lxc $vmid: final IPs: '$ips'"
    echo "$ips"
}

main
EOF
}

# Choose installation/update mode
echo -e "\n${YW}Choose action:${CL}"
echo -e "${GN}1)${CL} Install with automatic service (recommended)"
echo -e "${GN}2)${CL} Install command only (manual execution)"
echo -e "${GN}3)${CL} Update existing installation"
echo -e "${RD}4)${CL} Cancel"

while true; do
  read -p "Enter your choice (1-4): " choice
  case $choice in
    1)
      INSTALL_MODE="service"
      echo -e "${GN}✓ Selected: Service installation${CL}"
      break
      ;;
    2)
      INSTALL_MODE="command"
      echo -e "${GN}✓ Selected: Command-only installation${CL}"
      break
      ;;
    3)
      echo -e "${GN}✓ Selected: Update installation${CL}"
      update_installation
      exit 0
      ;;
    4)
      msg_error "Action cancelled."
      exit 0
      ;;
    *)
      msg_error "Please enter 1, 2, 3, or 4."
      ;;
  esac
done

echo -e "\n${YW}This will install ${APP} on ${hostname} in $INSTALL_MODE mode.${CL}"
while true; do
  read -p "Proceed? (y/n): " yn
  case $yn in
  [Yy]*)
    break
    ;;
  [Nn]*)
    msg_error "Installation cancelled."
    exit
    ;;
  *)
    msg_error "Please answer yes or no."
    ;;
  esac
done

if ! pveversion | grep -Eq "pve-manager/(8\.[0-4]|9\.[0-9]+)(\.[0-9]+)*"; then
  msg_error "This version of Proxmox Virtual Environment is not supported"
  msg_error "⚠ Requires Proxmox Virtual Environment Version 8.0–8.4 or 9.x."
  msg_error "Exiting..."
  sleep 2
  exit
fi

msg_info "Installing Dependencies"
apt-get update &>/dev/null
apt-get install -y ipcalc net-tools &>/dev/null
msg_ok "Installed Dependencies"

# Execute installation based on selected mode
if [[ "$INSTALL_MODE" == "service" ]]; then
  # Full service installation
  msg_info "Setting up IP-Tag Scripts"
  mkdir -p /opt/iptag
  msg_ok "Setup IP-Tag Scripts"

  # Migrate config if needed
  migrate_config

  # Interactive configuration setup
  if [[ ! -f /opt/iptag/iptag.conf ]]; then
    interactive_config_setup
    msg_info "Setup Default Config"
    generate_config >/opt/iptag/iptag.conf
    msg_ok "Setup default config"
  else
    stop_spinner
    echo -e "\n${YW}Configuration file already exists.${CL}"
    read -p "Do you want to reconfigure tag format and loop interval? (y/n): " reconfigure
    case $reconfigure in
      [Yy]*)
        interactive_config_setup
        msg_info "Updating Configuration"
        generate_config >/opt/iptag/iptag.conf
        msg_ok "Updated configuration file"
        ;;
      *)
        msg_ok "Keeping existing configuration file"
        ;;
    esac
  fi

  msg_info "Setup Main Function"
  generate_main_script >/opt/iptag/iptag
  chmod +x /opt/iptag/iptag
  msg_ok "Setup Main Function"

  msg_info "Creating Service"
  generate_service >/lib/systemd/system/iptag.service
  msg_ok "Created Service"

  msg_info "Starting Service"
  systemctl daemon-reload &>/dev/null
  systemctl enable -q --now iptag.service &>/dev/null
  msg_ok "Started Service"

  msg_info "Creating manual run command"
  cat <<'EOF' >/usr/local/bin/iptag-run
#!/usr/bin/env bash
CONFIG_FILE="/opt/iptag/iptag.conf"
SCRIPT_FILE="/opt/iptag/iptag"
if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo "✗ Main script not found: $SCRIPT_FILE"
  exit 1
fi
export FORCE_SINGLE_RUN=true
exec "$SCRIPT_FILE"
EOF
  chmod +x /usr/local/bin/iptag-run
  msg_ok "Created iptag-run command"
  
  echo -e "\n${GN}${APP} service installation completed successfully! ${CL}"
  echo -e "${YW}The service is now running automatically.${CL}"
  echo -e "${YW}You can also run it manually with: ${GN}iptag-run${CL}\n"
  
  # Show configuration information
  show_post_install_info
  
elif [[ "$INSTALL_MODE" == "command" ]]; then
  # Command-only installation
  install_command_only
  
  stop_spinner
  echo -e "\n${GN}${APP} command installation completed successfully! ${CL}"
  
  # Show configuration information
  show_post_install_info
fi

# Clean up any running spinner and exit
stop_spinner
exit 0
