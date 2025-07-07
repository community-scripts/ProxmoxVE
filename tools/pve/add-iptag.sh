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
CM=" ✔️ ${CL}"
CROSS=" ✖️ ${CL}"

# Error handler for displaying error messages
error_handler() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID >/dev/null; then
    kill $SPINNER_PID >/dev/null
  fi
  printf "\e[?25h"
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
}

# Spinner for progress indication
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

# Info message
msg_info() {
  local msg="$1"
  echo -ne "${TAB}${YW}${HOLD}${msg}${HOLD}"
  spinner &
  SPINNER_PID=$!
}

# Success message
msg_ok() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID >/dev/null; then
    kill $SPINNER_PID >/dev/null
  fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR}${CM}${GN}${msg}${CL}"
}

# Error message
msg_error() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID >/dev/null; then
    kill $SPINNER_PID >/dev/null
  fi
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
  msg_ok "Stopped IP-Tag service"

  # Create directory if it doesn't exist
  if [[ ! -d "/opt/iptag" ]]; then
    mkdir -p /opt/iptag
  fi

  # Create new config file (check if exists and ask user)
  if [[ -f "/opt/iptag/iptag.conf" ]]; then
    echo -e "\n${YW}Configuration file already exists.${CL}"
    while true; do
      read -p "Do you want to replace it with defaults? (y/n): " yn
      case $yn in
      [Yy]*)
        msg_info "Replacing configuration file"
        generate_config >/opt/iptag/iptag.conf
        msg_ok "Configuration file replaced with defaults"
        break
        ;;
      [Nn]*)
        echo -e "${GN}✔️ Keeping existing configuration file${CL}"
        break
        ;;
      *)
        echo -e "${RD}Please answer yes or no.${CL}"
        ;;
      esac
    done
  else
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

  msg_info "Restarting service"
  systemctl daemon-reload &>/dev/null
  systemctl enable -q --now iptag.service &>/dev/null
  msg_ok "Updated IP-Tag Scripts"
}

# Generate configuration file content
generate_config() {
  cat <<EOF
# Configuration file for LXC IP tagging

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
TAG_FORMAT="last_two_octets"

# Interval settings (in seconds) - optimized for lower CPU usage
LOOP_INTERVAL=300
VM_STATUS_CHECK_INTERVAL=600
FW_NET_INTERFACE_CHECK_INTERVAL=900
LXC_STATUS_CHECK_INTERVAL=300
FORCE_UPDATE_INTERVAL=7200

# Performance optimizations
VM_IP_CACHE_TTL=300
MAX_PARALLEL_VM_CHECKS=2

# LXC performance optimizations  
LXC_IP_CACHE_TTL=300
MAX_PARALLEL_LXC_CHECKS=2

# Extreme LXC optimizations
LXC_BATCH_SIZE=3
LXC_STATUS_CACHE_TTL=300
LXC_AGGRESSIVE_CACHING=true
LXC_SKIP_SLOW_METHODS=true

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

# Get VM IPs using multiple methods with performance optimizations
get_vm_ips() {
    local vmid=$1 ips=""
    local vm_config="/etc/pve/qemu-server/${vmid}.conf"
    [[ ! -f "$vm_config" ]] && return
    
    debug_log "vm $vmid: starting optimized IP detection"
    
    # Check if VM is running first (avoid expensive operations for stopped VMs)
    local vm_status=""
    if command -v qm >/dev/null 2>&1; then
        vm_status=$(qm status "$vmid" 2>/dev/null | awk '{print $2}')
    fi
    
    if [[ "$vm_status" != "running" ]]; then
        debug_log "vm $vmid: not running (status: $vm_status), skipping expensive detection"
        return
    fi
    
    # Cache for this execution
    local cache_file="/tmp/iptag_vm_${vmid}_cache"
    local cache_ttl=60  # 60 seconds cache
    
    # Check cache first
    if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0))) -lt $cache_ttl ]]; then
        local cached_ips=$(cat "$cache_file" 2>/dev/null)
        if [[ -n "$cached_ips" ]]; then
            debug_log "vm $vmid: using cached IPs: $cached_ips"
            echo "$cached_ips"
            return
        fi
    fi
    
    # Method 1: Quick ARP table lookup (fastest)
    local mac_addresses=$(grep -E "^net[0-9]+:" "$vm_config" | grep -oE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}" | head -3)
    debug_log "vm $vmid: found MACs: $mac_addresses"
    
    # Quick ARP check without forced refresh (most common case)
    for mac in $mac_addresses; do
        local mac_lower=$(echo "$mac" | tr '[:upper:]' '[:lower:]')
        local ip=$(ip neighbor show | grep "$mac_lower" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        if [[ -n "$ip" && "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            debug_log "vm $vmid: found IP $ip via quick ARP for MAC $mac_lower"
            ips+="$ip "
        fi
    done
    
    # Early exit if we found IPs via ARP
    if [[ -n "$ips" ]]; then
        local unique_ips=$(echo "$ips" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        unique_ips="${unique_ips% }"
        debug_log "vm $vmid: early exit with IPs: '$unique_ips'"
        echo "$unique_ips" > "$cache_file"
        echo "$unique_ips"
        return
    fi
    
    # Method 2: QM guest agent (fast if available)
    if command -v qm >/dev/null 2>&1; then
        local qm_ips=$(timeout 3 qm guest cmd "$vmid" network-get-interfaces 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v "127.0.0.1" | head -2)
        for qm_ip in $qm_ips; do
            if [[ "$qm_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                debug_log "vm $vmid: found IP $qm_ip via qm guest cmd"
                ips+="$qm_ip "
            fi
        done
    fi
    
    # Early exit if we found IPs via QM
    if [[ -n "$ips" ]]; then
        local unique_ips=$(echo "$ips" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        unique_ips="${unique_ips% }"
        debug_log "vm $vmid: early exit with QM IPs: '$unique_ips'"
        echo "$unique_ips" > "$cache_file"
        echo "$unique_ips"
        return
    fi
    
    # Method 3: DHCP leases check (medium cost)
    for mac in $mac_addresses; do
        local mac_lower=$(echo "$mac" | tr '[:upper:]' '[:lower:]')
        
        for dhcp_file in "/var/lib/dhcp/dhcpd.leases" "/var/lib/dhcpcd5/dhcpcd.leases" "/tmp/dhcp.leases"; do
            if [[ -f "$dhcp_file" ]]; then
                local dhcp_ip=$(timeout 2 grep -A 10 "ethernet $mac_lower" "$dhcp_file" 2>/dev/null | grep "binding state active" -A 5 | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -1)
                if [[ -n "$dhcp_ip" && "$dhcp_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                    debug_log "vm $vmid: found IP $dhcp_ip via DHCP leases for MAC $mac_lower"
                    ips+="$dhcp_ip "
                    break 2
                fi
            fi
        done
    done
    
    # Early exit if we found IPs via DHCP
    if [[ -n "$ips" ]]; then
        local unique_ips=$(echo "$ips" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        unique_ips="${unique_ips% }"
        debug_log "vm $vmid: early exit with DHCP IPs: '$unique_ips'"
        echo "$unique_ips" > "$cache_file"
        echo "$unique_ips"
        return
    fi
    
    # Method 4: Limited network discovery (expensive - only if really needed)
    debug_log "vm $vmid: falling back to limited network discovery"
    
    for mac in $mac_addresses; do
        local mac_lower=$(echo "$mac" | tr '[:upper:]' '[:lower:]')
        
        # Get bridge interfaces
        local bridges=$(grep -E "^net[0-9]+:" "$vm_config" | grep -oE "bridge=\w+" | cut -d= -f2 | head -1)
        for bridge in $bridges; do
            if [[ -n "$bridge" && -d "/sys/class/net/$bridge" ]]; then
                # Get bridge IP range
                local bridge_ip=$(ip addr show "$bridge" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+' | head -1)
                if [[ -n "$bridge_ip" ]]; then
                    local network=$(echo "$bridge_ip" | cut -d'/' -f1)
                    debug_log "vm $vmid: limited scan on bridge $bridge network $bridge_ip"
                    
                    # Force ARP refresh with broadcast ping (limited)
                    IFS='.' read -r a b c d <<< "$network"
                    local broadcast="$a.$b.$c.255"
                    timeout 1 ping -c 1 -b "$broadcast" >/dev/null 2>&1 || true
                    
                    # Check ARP again after refresh
                    sleep 0.5
                    local ip=$(ip neighbor show | grep "$mac_lower" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
                    if [[ -n "$ip" && "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                        debug_log "vm $vmid: found IP $ip via ARP after broadcast for MAC $mac_lower"
                        ips+="$ip "
                        break 2
                    fi
                    
                    # Only do very limited ping scan (reduced range)
                    IFS='.' read -r a b c d <<< "$network"
                    local base_net="$a.$b.$c"
                    
                    # Try only most common ranges (much smaller than before)
                    for last_octet in {100..105} {200..205}; do
                        local test_ip="$base_net.$last_octet"
                        
                        # Very quick ping test (reduced timeout)
                        if timeout 0.2 ping -c 1 -W 1 "$test_ip" >/dev/null 2>&1; then
                            # Check if this IP corresponds to our MAC
                            sleep 0.1
                            local found_mac=$(ip neighbor show "$test_ip" 2>/dev/null | grep -oE "([0-9a-f]{2}:){5}[0-9a-f]{2}")
                            if [[ "$found_mac" == "$mac_lower" ]]; then
                                debug_log "vm $vmid: found IP $test_ip via limited ping scan for MAC $mac_lower"
                                ips+="$test_ip "
                                break 2
                            fi
                        fi
                    done
                    
                    # Skip extended scanning entirely (too expensive)
                    debug_log "vm $vmid: skipping extended scan to preserve CPU"
                fi
            fi
        done
    done
    
    # Method 5: Static configuration check (fast)
    if [[ -z "$ips" ]]; then
        debug_log "vm $vmid: checking for static IP configuration"
        
        # Check cloud-init configuration if exists
        local cloudinit_file="/var/lib/vz/snippets/${vmid}-cloud-init.yml"
        if [[ -f "$cloudinit_file" ]]; then
            local static_ip=$(grep -E "addresses?:" "$cloudinit_file" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
            if [[ -n "$static_ip" && "$static_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                debug_log "vm $vmid: found static IP $static_ip in cloud-init config"
                ips+="$static_ip "
            fi
        fi
        
        # Check VM config for any IP hints
        local config_ip=$(grep -E "(ip=|gw=)" "$vm_config" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        if [[ -n "$config_ip" && "$config_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            debug_log "vm $vmid: found IP hint $config_ip in VM config"
            ips+="$config_ip "
        fi
    fi
    
    # Remove duplicates and cache result
    local unique_ips=$(echo "$ips" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    unique_ips="${unique_ips% }"
    
    # Cache the result (even if empty)
    echo "$unique_ips" > "$cache_file"
    
    debug_log "vm $vmid: final optimized IPs: '$unique_ips'"
    echo "$unique_ips"
}

# Update tags for container or VM
update_tags() {
    local type="$1" vmid="$2"
    local current_ips_full

    if [[ "$type" == "lxc" ]]; then
        current_ips_full=$(get_lxc_ips "${vmid}")
        local current_tags_raw=$(pct config "${vmid}" 2>/dev/null | grep tags | awk '{print $2}')
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

    # Add new IP tags
    for new_ip in "${formatted_ips[@]}"; do
        next_tags+=("$new_ip")
    done

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
        log_info "Processing ${WHITE}${count}${NC} LXC container(s) in parallel"
        
        # Clean up old cache files before processing LXC
        cleanup_vm_cache
        
        # Process LXC containers in parallel for better performance
        process_lxc_parallel "${vmids[@]}"
    else
        log_info "Processing ${WHITE}${count}${NC} virtual machine(s) in parallel"
        
        # Clean up old cache files before processing VMs
        cleanup_vm_cache
        
        # Process VMs in parallel for better performance
        process_vms_parallel "${vmids[@]}"
    fi
    
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
    local current_time changes_detected=false
    current_time=$(date +%s)
    
    # Periodic cache cleanup (every 10 minutes)
    local time_since_last_cleanup=$((current_time - ${last_cleanup_time:-0}))
    if [[ $time_since_last_cleanup -ge 600 ]]; then
        cleanup_vm_cache
        last_cleanup_time=$current_time
        debug_log "Performed periodic cache cleanup"
    fi

    # Check LXC status
    local time_since_last_lxc_check=$((current_time - last_lxc_status_check_time))
    if [[ "${LXC_STATUS_CHECK_INTERVAL:-60}" -gt 0 ]] && \
       [[ "${time_since_last_lxc_check}" -ge "${LXC_STATUS_CHECK_INTERVAL:-60}" ]]; then
        last_lxc_status_check_time=${current_time}
        if check_status_changed "lxc"; then
            changes_detected=true
            log_warning "LXC status changes detected, updating tags"
            update_all_tags "lxc"
            last_update_lxc_time=${current_time}
        fi
    fi

    # Check VM status
    local time_since_last_vm_check=$((current_time - last_vm_status_check_time))
    if [[ "${VM_STATUS_CHECK_INTERVAL:-60}" -gt 0 ]] && \
       [[ "${time_since_last_vm_check}" -ge "${VM_STATUS_CHECK_INTERVAL:-60}" ]]; then
        last_vm_status_check_time=${current_time}
        if check_status_changed "vm"; then
            changes_detected=true
            log_warning "VM status changes detected, updating tags"
            update_all_tags "vm"
            last_update_vm_time=${current_time}
        fi
    fi

    # Check network interface changes
    local time_since_last_fw_check=$((current_time - last_fw_net_interface_check_time))
    if [[ "${FW_NET_INTERFACE_CHECK_INTERVAL:-60}" -gt 0 ]] && \
       [[ "${time_since_last_fw_check}" -ge "${FW_NET_INTERFACE_CHECK_INTERVAL:-60}" ]]; then
        last_fw_net_interface_check_time=${current_time}
        if check_status_changed "fw"; then
            changes_detected=true
            log_warning "Network interface changes detected, updating all tags"
            update_all_tags "lxc"
            update_all_tags "vm"
            last_update_lxc_time=${current_time}
            last_update_vm_time=${current_time}
        fi
    fi

    # Force update if needed
    for type in "lxc" "vm"; do
        local last_update_var="last_update_${type}_time"
        local time_since_last_update=$((current_time - ${!last_update_var}))
        if [[ ${time_since_last_update} -ge ${FORCE_UPDATE_INTERVAL:-1800} ]]; then
            changes_detected=true
            local minutes=$((${FORCE_UPDATE_INTERVAL:-1800} / 60))
            if [[ "$type" == "lxc" ]]; then
                log_info "Scheduled LXC update (every ${minutes} minutes)"
            else
                log_info "Scheduled VM update (every ${minutes} minutes)"
            fi
            update_all_tags "$type"
            eval "${last_update_var}=${current_time}"
        fi
    done
}

# Initialize time variables
declare -g last_lxc_status="" last_vm_status="" last_fw_status=""
declare -g last_lxc_status_check_time=0 last_vm_status_check_time=0 last_fw_net_interface_check_time=0
declare -g last_update_lxc_time=0 last_update_vm_time=0 last_cleanup_time=0

# Main loop
main() {
    # Display startup message
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_success "IP-Tag service started successfully"
    echo -e "${BLUE}ℹ${NC} Loop interval: ${WHITE}${LOOP_INTERVAL:-$DEFAULT_CHECK_INTERVAL}${NC} seconds"
    echo -e "${BLUE}ℹ${NC} Debug mode: ${WHITE}${DEBUG:-false}${NC}"
    echo -e "${BLUE}ℹ${NC} Tag format: ${WHITE}${TAG_FORMAT:-$DEFAULT_TAG_FORMAT}${NC}"
    echo -e "${BLUE}ℹ${NC} Allowed CIDRs: ${WHITE}${CIDR_LIST[*]}${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    while true; do
        check
        sleep "${LOOP_INTERVAL:-300}"
    done
}

# Cache cleanup function
cleanup_vm_cache() {
    local cache_dir="/tmp"
    local vm_cache_ttl=${VM_IP_CACHE_TTL:-120}
    local lxc_cache_ttl=${LXC_IP_CACHE_TTL:-120}
    local status_cache_ttl=${LXC_STATUS_CACHE_TTL:-30}
    local current_time=$(date +%s)
    
    debug_log "Starting extreme cache cleanup"
    
    # Clean VM cache files
    for cache_file in "$cache_dir"/iptag_vm_*_cache; do
        if [[ -f "$cache_file" ]]; then
            local file_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
            if [[ $((current_time - file_time)) -gt $vm_cache_ttl ]]; then
                rm -f "$cache_file" 2>/dev/null
                debug_log "Cleaned up expired VM cache file: $cache_file"
            fi
        fi
    done
    
    # Clean LXC IP cache files
    for cache_file in "$cache_dir"/iptag_lxc_*_cache; do
        if [[ -f "$cache_file" ]]; then
            local file_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
            if [[ $((current_time - file_time)) -gt $lxc_cache_ttl ]]; then
                rm -f "$cache_file" 2>/dev/null
                # Also clean meta files
                rm -f "${cache_file}.meta" 2>/dev/null
                debug_log "Cleaned up expired LXC cache file: $cache_file"
            fi
        fi
    done
    
    # Clean LXC status cache files (shorter TTL)
    for cache_file in "$cache_dir"/iptag_lxc_status_*_cache; do
        if [[ -f "$cache_file" ]]; then
            local file_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
            if [[ $((current_time - file_time)) -gt $status_cache_ttl ]]; then
                rm -f "$cache_file" 2>/dev/null
                debug_log "Cleaned up expired LXC status cache: $cache_file"
            fi
        fi
    done
    
    # Clean LXC PID cache files (60 second TTL)
    for cache_file in "$cache_dir"/iptag_lxc_pid_*_cache; do
        if [[ -f "$cache_file" ]]; then
            local file_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
            if [[ $((current_time - file_time)) -gt 60 ]]; then
                rm -f "$cache_file" 2>/dev/null
                debug_log "Cleaned up expired LXC PID cache: $cache_file"
            fi
        fi
    done
    
    # Clean any orphaned meta files
    for meta_file in "$cache_dir"/iptag_*.meta; do
        if [[ -f "$meta_file" ]]; then
            local base_file="${meta_file%.meta}"
            if [[ ! -f "$base_file" ]]; then
                rm -f "$meta_file" 2>/dev/null
                debug_log "Cleaned up orphaned meta file: $meta_file"
            fi
        fi
    done
    
    debug_log "Completed extreme cache cleanup"
}

# Parallel VM processing function
process_vms_parallel() {
    local vm_list=("$@")
    local max_parallel=${MAX_PARALLEL_VM_CHECKS:-5}
    local job_count=0
    local pids=()
    local pid_start_times=()
    
    for vmid in "${vm_list[@]}"; do
        if [[ $job_count -ge $max_parallel ]]; then
            local pid_to_wait="${pids[0]}"
            local start_time="${pid_start_times[0]}"
            local waited=0
            while kill -0 "$pid_to_wait" 2>/dev/null && [[ $waited -lt 10 ]]; do
                sleep 1
                ((waited++))
            done
            if kill -0 "$pid_to_wait" 2>/dev/null; then
                kill -9 "$pid_to_wait" 2>/dev/null
                log_warning "VM parallel: killed stuck process $pid_to_wait after 10s timeout"
            else
                wait "$pid_to_wait"
            fi
            pids=("${pids[@]:1}")
            pid_start_times=("${pid_start_times[@]:1}")
            ((job_count--))
        fi
        # Start background job
        (update_tags "vm" "$vmid") &
        pids+=($!)
        pid_start_times+=("$(date +%s)")
        ((job_count++))
    done
    for i in "${!pids[@]}"; do
        local pid="${pids[$i]}"
        local waited=0
        while kill -0 "$pid" 2>/dev/null && [[ $waited -lt 10 ]]; do
            sleep 1
            ((waited++))
        done
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null
            log_warning "VM parallel: killed stuck process $pid after 10s timeout"
        else
            wait "$pid"
        fi
    done
}

# Parallel LXC processing function
process_lxc_parallel() {
    local lxc_list=("$@")
    local max_parallel=${MAX_PARALLEL_LXC_CHECKS:-7}
    local batch_size=${LXC_BATCH_SIZE:-20}
    local job_count=0
    local pids=()
    local pid_start_times=()
    
    debug_log "Starting parallel LXC processing: ${#lxc_list[@]} containers, max_parallel=$max_parallel"
    
    if [[ ${#lxc_list[@]} -gt 5 ]]; then
        debug_log "Pre-loading LXC statuses for ${#lxc_list[@]} containers"
        local all_statuses=$(pct list 2>/dev/null)
        for vmid in "${lxc_list[@]}"; do
            local status=$(echo "$all_statuses" | grep "^$vmid" | awk '{print $2}')
            if [[ -n "$status" ]]; then
                local status_cache_file="/tmp/iptag_lxc_status_${vmid}_cache"
                echo "$status" > "$status_cache_file" 2>/dev/null &
            fi
        done
        wait
        debug_log "Completed batch status pre-loading"
    fi
    for vmid in "${lxc_list[@]}"; do
        if [[ $job_count -ge $max_parallel ]]; then
            local pid_to_wait="${pids[0]}"
            local start_time="${pid_start_times[0]}"
            local waited=0
            while kill -0 "$pid_to_wait" 2>/dev/null && [[ $waited -lt 10 ]]; do
                sleep 1
                ((waited++))
            done
            if kill -0 "$pid_to_wait" 2>/dev/null; then
                kill -9 "$pid_to_wait" 2>/dev/null
                log_warning "LXC parallel: killed stuck process $pid_to_wait after 10s timeout"
            else
                wait "$pid_to_wait"
            fi
            pids=("${pids[@]:1}")
            pid_start_times=("${pid_start_times[@]:1}")
            ((job_count--))
        fi
        # Start background job with higher priority
        (update_tags "lxc" "$vmid") &
        pids+=($!)
        pid_start_times+=("$(date +%s)")
        ((job_count++))
    done
    for i in "${!pids[@]}"; do
        local pid="${pids[$i]}"
        local waited=0
        while kill -0 "$pid" 2>/dev/null && [[ $waited -lt 10 ]]; do
            sleep 1
            ((waited++))
        done
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null
            log_warning "LXC parallel: killed stuck process $pid after 10s timeout"
        else
            wait "$pid"
        fi
    done
    debug_log "Completed parallel LXC processing"
}

# Optimized LXC IP detection with caching and alternative methods
get_lxc_ips() {
    local vmid=$1
    local status_cache_file="/tmp/iptag_lxc_status_${vmid}_cache"
    local status_cache_ttl=${LXC_STATUS_CACHE_TTL:-30}
    
    debug_log "lxc $vmid: starting extreme optimized IP detection"
    
    # Check status cache first (avoid expensive pct status calls)
    local lxc_status=""
    if [[ -f "$status_cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$status_cache_file" 2>/dev/null || echo 0))) -lt $status_cache_ttl ]]; then
        lxc_status=$(cat "$status_cache_file" 2>/dev/null)
        debug_log "lxc $vmid: using cached status: $lxc_status"
    else
        lxc_status=$(pct status "${vmid}" 2>/dev/null | awk '{print $2}')
        echo "$lxc_status" > "$status_cache_file" 2>/dev/null
        debug_log "lxc $vmid: fetched fresh status: $lxc_status"
    fi
    
    if [[ "$lxc_status" != "running" ]]; then
        debug_log "lxc $vmid: not running (status: $lxc_status)"
        return
    fi
    
    local ips=""
    local method_used=""
    
    # EXTREME Method 1: Direct Proxmox config inspection (super fast)
    debug_log "lxc $vmid: trying direct Proxmox config inspection"
    local pve_lxc_config="/etc/pve/lxc/${vmid}.conf"
    if [[ -f "$pve_lxc_config" ]]; then
        local static_ip=$(grep -E "^net[0-9]+:" "$pve_lxc_config" 2>/dev/null | grep -oE 'ip=([0-9]{1,3}\.){3}[0-9]{1,3}' | cut -d'=' -f2 | head -1)
        debug_log "lxc $vmid: [CONFIG] static_ip='$static_ip' (from $pve_lxc_config)"
        if [[ -n "$static_ip" && "$static_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            debug_log "lxc $vmid: found static IP $static_ip in Proxmox config"
            ips="$static_ip"
            method_used="proxmox_config"
        fi
    else
        debug_log "lxc $vmid: [CONFIG] config file not found: $pve_lxc_config"
    fi
    
    # EXTREME Method 2: Direct network namespace inspection (fastest dynamic)
    if [[ -z "$ips" ]]; then
        debug_log "lxc $vmid: trying optimized namespace inspection"
        local ns_file="/var/lib/lxc/${vmid}/rootfs/proc/net/fib_trie"
        if [[ -f "$ns_file" ]]; then
            local ns_ip=$(timeout 1 grep -m1 -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$ns_file" 2>/dev/null | grep -v '127.0.0.1' | head -1)
            debug_log "lxc $vmid: [NAMESPACE] ns_ip='$ns_ip'"
            if [[ -n "$ns_ip" ]] && is_valid_ipv4 "$ns_ip"; then
                debug_log "lxc $vmid: found IP $ns_ip via namespace inspection"
                ips="$ns_ip"
                method_used="namespace"
            fi
        else
            debug_log "lxc $vmid: [NAMESPACE] ns_file not found: $ns_file"
        fi
    fi
    
    # EXTREME Method 3: Batch ARP table lookup (if namespace failed)
    if [[ -z "$ips" ]]; then
        debug_log "lxc $vmid: trying batch ARP lookup"
        local bridge_name=""; local mac_addr=""
        if [[ -f "$pve_lxc_config" ]]; then
            bridge_name=$(grep -Eo 'bridge=[^,]+' "$pve_lxc_config" | head -1 | cut -d'=' -f2)
            mac_addr=$(grep -Eo 'hwaddr=([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' "$pve_lxc_config" | head -1 | cut -d'=' -f2)
            debug_log "lxc $vmid: [ARP] bridge_name='$bridge_name' mac_addr='$mac_addr' (from $pve_lxc_config)"
        fi
        if [[ -z "$bridge_name" || -z "$mac_addr" ]]; then
            local lxc_config="/var/lib/lxc/${vmid}/config"
            if [[ -f "$lxc_config" ]]; then
                [[ -z "$bridge_name" ]] && bridge_name=$(grep "lxc.net.0.link" "$lxc_config" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
                [[ -z "$mac_addr" ]] && mac_addr=$(grep "lxc.net.0.hwaddr" "$lxc_config" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
                debug_log "lxc $vmid: [ARP] bridge_name='$bridge_name' mac_addr='$mac_addr' (from $lxc_config)"
            else
                debug_log "lxc $vmid: [ARP] lxc config not found: $lxc_config"
            fi
        fi
        if [[ -n "$bridge_name" && -n "$mac_addr" ]]; then
            local bridge_ip=$(ip neighbor show dev "$bridge_name" 2>/dev/null | grep "$mac_addr" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
            debug_log "lxc $vmid: [ARP] bridge_ip='$bridge_ip'"
            if [[ -n "$bridge_ip" && "$bridge_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                debug_log "lxc $vmid: found IP $bridge_ip via ARP table"
                ips="$bridge_ip"
                method_used="arp_table"
            fi
        fi
    fi
    
    # EXTREME Method 4: Fast process namespace (if ARP failed)
    if [[ -z "$ips" ]] && [[ "${LXC_SKIP_SLOW_METHODS:-true}" != "true" ]]; then
        debug_log "lxc $vmid: trying fast process namespace"
        local pid_cache_file="/tmp/iptag_lxc_pid_${vmid}_cache"
        local container_pid=""
        if [[ -f "$pid_cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$pid_cache_file" 2>/dev/null || echo 0))) -lt 60 ]]; then
            container_pid=$(cat "$pid_cache_file" 2>/dev/null)
        else
            container_pid=$(pct list 2>/dev/null | grep "^$vmid" | awk '{print $3}')
            [[ -n "$container_pid" && "$container_pid" != "-" ]] && echo "$container_pid" > "$pid_cache_file"
        fi
        debug_log "lxc $vmid: [PROCESS_NS] container_pid='$container_pid'"
        if [[ -n "$container_pid" && "$container_pid" != "-" ]]; then
            local ns_ip=$(timeout 1 nsenter -t "$container_pid" -n ip -4 addr show 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1)
            debug_log "lxc $vmid: [PROCESS_NS] ns_ip='$ns_ip'"
            if [[ -n "$ns_ip" ]] && is_valid_ipv4 "$ns_ip"; then
                debug_log "lxc $vmid: found IP $ns_ip via process namespace"
                ips="$ns_ip"
                method_used="process_ns"
            fi
        fi
    fi
    
    # Fallback: always do lxc-attach/pct exec with timeout if nothing found
    if [[ -z "$ips" ]]; then
        debug_log "lxc $vmid: trying fallback lxc-attach (forced)"
        local attach_ip=""
        attach_ip=$(timeout 7s lxc-attach -n "$vmid" -- ip -4 addr show 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1)
        local attach_status=$?
        debug_log "lxc $vmid: [LXC_ATTACH] attach_ip='$attach_ip' status=$attach_status"
        if [[ $attach_status -eq 124 ]]; then
            debug_log "lxc $vmid: lxc-attach timed out after 7s"
        fi
        if [[ -n "$attach_ip" ]] && is_valid_ipv4 "$attach_ip"; then
            debug_log "lxc $vmid: found IP $attach_ip via lxc-attach (forced)"
            ips="$attach_ip"
            method_used="lxc_attach_forced"
        fi
    fi
    if [[ -z "$ips" ]]; then
        debug_log "lxc $vmid: trying fallback pct exec (forced)"
        local pct_ip=""
        pct_ip=$(timeout 7s pct exec "$vmid" -- ip -4 addr show 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1)
        local pct_status=$?
        debug_log "lxc $vmid: [PCT_EXEC] pct_ip='$pct_ip' status=$pct_status"
        if [[ $pct_status -eq 124 ]]; then
            debug_log "lxc $vmid: pct exec timed out after 7s"
        fi
        if [[ -n "$pct_ip" ]] && is_valid_ipv4 "$pct_ip"; then
            debug_log "lxc $vmid: found IP $pct_ip via pct exec (forced)"
            ips="$pct_ip"
            method_used="pct_exec_forced"
        fi
    fi
    
    debug_log "lxc $vmid: [RESULT] ips='$ips' method='$method_used'"
    echo "$ips"
}

main
EOF
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
    *)
      msg_error "Please answer yes or no."
      ;;
    esac
  done
fi

while true; do
  read -p "This will install ${APP} on ${hostname}. Proceed? (y/n): " yn
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

if ! pveversion | grep -Eq "pve-manager/8\.[0-4](\.[0-9]+)*"; then
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
  generate_config >/opt/iptag/iptag.conf
  msg_ok "Setup default config"
else
  msg_ok "Default config already exists"
fi

msg_info "Setup Main Function"
if [[ ! -f /opt/iptag/iptag ]]; then
  generate_main_script >/opt/iptag/iptag
  chmod +x /opt/iptag/iptag
  msg_ok "Setup Main Function"
else
  msg_ok "Main Function already exists"
fi

msg_info "Creating Service"
if [[ ! -f /lib/systemd/system/iptag.service ]]; then
  generate_service >/lib/systemd/system/iptag.service
  msg_ok "Created Service"
else
  msg_ok "Service already exists."
fi

msg_ok "Setup IP-Tag Scripts"

msg_info "Starting Service"
systemctl daemon-reload &>/dev/null
systemctl enable -q --now iptag.service &>/dev/null
msg_ok "Started Service"

msg_info "Restarting Service with optimizations"
systemctl restart iptag.service &>/dev/null
msg_ok "Service restarted with CPU optimizations"

msg_info "Creating manual run command"
cat <<'EOF' >/usr/local/bin/iptag-run
#!/usr/bin/env bash
CONFIG_FILE="/opt/iptag/iptag.conf"
SCRIPT_FILE="/opt/iptag/iptag"
if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo "❌ Main script not found: $SCRIPT_FILE"
  exit 1
fi
export FORCE_SINGLE_RUN=true
exec "$SCRIPT_FILE"
EOF
chmod +x /usr/local/bin/iptag-run
msg_ok "Created iptag-run executable - You can execute this manually by entering “iptag-run” in the Proxmox host, so the script is executed by hand."

SPINNER_PID=""
echo -e "\n${APP} installation completed successfully! ${CL}\n"

# Proper script termination
exit 0
