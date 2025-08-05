#!/usr/bin/env bash

# Creates a systemd service to disable NIC offloading features for Intel e1000e and e1000 interfaces
# Author: rcastley
# License: MIT

YW=$(echo "\033[33m")
YWB=$'\e[93m'
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
TAB="  "
CM="${TAB}✔️${TAB}"
CROSS="${TAB}✖️${TAB}"
INFO="${TAB}ℹ️${TAB}${CL}"
WARN="${TAB}⚠️${TAB}${CL}"

function header_info {
clear
cat <<"EOF"

    _   ____________   ____  __________                ___                ____  _            __    __
   / | / /  _/ ____/  / __ \/ __/ __/ /___  ____ _____/ (_)___  ____ _   / __ \(_)________ _/ /_  / /__  _____
  /  |/ // // /      / / / / /_/ /_/ / __ \/ __ `/ __  / / __ \/ __ `/  / / / / / ___/ __ `/ __ \/ / _ \/ ___/
 / /|  // // /___   / /_/ / __/ __/ / /_/ / /_/ / /_/ / / / / / /_/ /  / /_/ / (__  ) /_/ / /_/ / /  __/ /
/_/ |_/___/\____/   \____/_/ /_/ /_/\____/\__,_/\__,_/_/_/ /_/\__, /  /_____/_/____/\__,_/_.___/_/\___/_/
                                                             /____/
Enhanced version supporting both e1000e and e1000 drivers

EOF
}

header_info

function msg_info() { echo -e "${INFO} ${YW}${1}...${CL}"; }
function msg_ok() { echo -e "${CM} ${GN}${1}${CL}"; }
function msg_error() { echo -e "${CROSS} ${RD}${1}${CL}"; }
function msg_warn() { echo -e "${WARN} ${YWB}${1}"; }

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    msg_error "Error: This script must be run as root."
    exit 1
fi

if ! command -v ethtool >/dev/null 2>&1; then
    msg_info "Installing ethtool"
    apt-get update &>/dev/null
    apt-get install -y ethtool &>/dev/null || { msg_error "Failed to install ethtool. Exiting."; exit 1; }
    msg_ok "ethtool installed successfully"
fi

# Get list of network interfaces using Intel e1000e or e1000 drivers
INTERFACES=()
COUNT=0

msg_info "Searching for Intel e1000e and e1000 interfaces"

for device in /sys/class/net/*; do
    interface="$(basename "$device")"  # or adjust the rest of the usages below, as mostly you'll use the path anyway
    # Skip loopback interface and virtual interfaces
    if [[ "$interface" != "lo" ]] && [[ ! "$interface" =~ ^(tap|fwbr|veth|vmbr|bonding_masters) ]]; then
        # Check if the interface uses the e1000e or e1000 driver
        driver=$(basename $(readlink -f /sys/class/net/$interface/device/driver 2>/dev/null) 2>/dev/null)
        
        if [[ "$driver" == "e1000e" ]] || [[ "$driver" == "e1000" ]]; then
            # Get MAC address for additional identification
            mac=$(cat /sys/class/net/$interface/address 2>/dev/null)
            INTERFACES+=("$interface" "Intel $driver NIC ($mac)")
            ((COUNT++))
        fi
    fi
done

# Check if any Intel e1000e/e1000 interfaces were found
if [ ${#INTERFACES[@]} -eq 0 ]; then
    whiptail --title "Error" --msgbox "No Intel e1000e or e1000 network interfaces found!" 10 60
    msg_error "No Intel e1000e or e1000 network interfaces found! Exiting."
    exit 1
fi

msg_ok "Found ${BL}$COUNT${GN} Intel e1000e/e1000 interfaces"

# Create a checklist for interface selection with all interfaces initially checked
INTERFACES_CHECKLIST=()
for ((i=0; i<${#INTERFACES[@]}; i+=2)); do
    INTERFACES_CHECKLIST+=("${INTERFACES[i]}" "${INTERFACES[i+1]}" "ON")
done

# Show interface selection checklist
SELECTED_INTERFACES=$(whiptail --backtitle "Intel e1000e/e1000 NIC Offloading Disabler" --title "Network Interfaces" \
    --separate-output --checklist "Select Intel e1000e/e1000 network interfaces\n(Space to toggle, Enter to confirm):" 15 80 6 \
    "${INTERFACES_CHECKLIST[@]}" 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus != 0 ]; then
    msg_info "User canceled. Exiting."
    exit 0
fi

# Check if any interfaces were selected
if [ -z "$SELECTED_INTERFACES" ]; then
    msg_error "No interfaces selected. Exiting."
    exit 0
fi

# Convert the selected interfaces into an array
readarray -t INTERFACE_ARRAY <<< "$SELECTED_INTERFACES"

# Show the number of selected interfaces
INTERFACE_COUNT=${#INTERFACE_ARRAY[@]}

# Print selected interfaces with their driver types
for iface in "${INTERFACE_ARRAY[@]}"; do
    driver=$(basename $(readlink -f /sys/class/net/$iface/device/driver 2>/dev/null) 2>/dev/null)
    msg_ok "Selected interface: ${BL}$iface${GN} (${BL}$driver${GN})"
done

# Ask for confirmation with the list of selected interfaces
CONFIRMATION_MSG="You have selected the following interface(s):\n\n"
for iface in "${INTERFACE_ARRAY[@]}"; do
    SPEED=$(cat /sys/class/net/$iface/speed 2>/dev/null || echo "Unknown")
    MAC=$(cat /sys/class/net/$iface/address 2>/dev/null)
    DRIVER=$(basename $(readlink -f /sys/class/net/$iface/device/driver 2>/dev/null) 2>/dev/null)
    CONFIRMATION_MSG+="- $iface (Driver: $DRIVER, MAC: $MAC, Speed: ${SPEED}Mbps)\n"
done
CONFIRMATION_MSG+="\nThis will create systemd service(s) to disable offloading features.\n\nProceed?"

if ! whiptail --backtitle "Intel e1000e/e1000 NIC Offloading Disabler" --title "Confirmation" \
    --yesno "$CONFIRMATION_MSG" 20 80; then
    msg_info "User canceled. Exiting."
    exit 0
fi

# Loop through all selected interfaces and create services for each
for SELECTED_INTERFACE in "${INTERFACE_ARRAY[@]}"; do
    # Get the driver type for this specific interface
    DRIVER=$(basename $(readlink -f /sys/class/net/$SELECTED_INTERFACE/device/driver 2>/dev/null) 2>/dev/null)
    
    # Create service name for this interface
    SERVICE_NAME="disable-nic-offload-$SELECTED_INTERFACE.service"
    SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
    
    # Create the service file with driver-specific optimizations
    msg_info "Creating systemd service for interface: ${BL}$SELECTED_INTERFACE${YW} (${BL}$DRIVER${YW})"
    
    # Start with the common part of the service file
    cat > "$SERVICE_PATH" << EOF
[Unit]
Description=Disable NIC offloading for Intel $DRIVER interface $SELECTED_INTERFACE
After=network.target

[Service]
Type=oneshot
# Disable all offloading features for Intel $DRIVER
ExecStart=/sbin/ethtool -K $SELECTED_INTERFACE gso off gro off tso off tx off rx off rxvlan off txvlan off sg off
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    # Check if service file was created successfully
    if [ ! -f "$SERVICE_PATH" ]; then
        whiptail --title "Error" --msgbox "Failed to create service file for $SELECTED_INTERFACE!" 10 50
        msg_error "Failed to create service file for $SELECTED_INTERFACE! Skipping to next interface."
        continue
    fi

    # Configure this service
    {
        echo "25"; sleep 0.2
        # Reload systemd to recognize the new service
        systemctl daemon-reload
        echo "50"; sleep 0.2
        # Start the service
        systemctl start "$SERVICE_NAME"
        echo "75"; sleep 0.2
        # Enable the service to start on boot
        systemctl enable "$SERVICE_NAME"
        echo "100"; sleep 0.2
    } | whiptail --backtitle "Intel e1000e/e1000 NIC Offloading Disabler" --gauge "Configuring service for $SELECTED_INTERFACE..." 10 80 0

    # Individual service status
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        SERVICE_STATUS="Active"
    else
        SERVICE_STATUS="Inactive"
    fi

    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        BOOT_STATUS="Enabled"
    else
        BOOT_STATUS="Disabled"
    fi

    # Show individual service results
    msg_ok "Service for ${BL}$SELECTED_INTERFACE${GN} (${BL}$DRIVER${GN}) created and enabled!"
    msg_info "${TAB}Service: ${BL}$SERVICE_NAME${YW}"
    msg_info "${TAB}Status: ${BL}$SERVICE_STATUS${YW}"
    msg_info "${TAB}Start on boot: ${BL}$BOOT_STATUS${YW}"
done

# Prepare summary of all interfaces
SUMMARY_MSG="Services created successfully!\n\n"
SUMMARY_MSG+="Configured Interfaces:\n"

for iface in "${INTERFACE_ARRAY[@]}"; do
    SERVICE_NAME="disable-nic-offload-$iface.service"
    DRIVER=$(basename $(readlink -f /sys/class/net/$iface/device/driver 2>/dev/null) 2>/dev/null)
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        SVC_STATUS="Active"
    else
        SVC_STATUS="Inactive"
    fi

    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        BOOT_SVC_STATUS="Enabled"
    else
        BOOT_SVC_STATUS="Disabled"
    fi

    SUMMARY_MSG+="- $iface ($DRIVER): $SVC_STATUS, Boot: $BOOT_SVC_STATUS\n"
done

# Show summary results
whiptail --backtitle "Intel e1000e/e1000 NIC Offloading Disabler" --title "Success" --msgbox "$SUMMARY_MSG" 22 80

msg_ok "Intel e1000e/e1000 optimization complete for ${#INTERFACE_ARRAY[@]} interface(s)!"

# Show verification commands
echo ""
msg_info "Verification commands:"
for iface in "${INTERFACE_ARRAY[@]}"; do
    echo -e "${TAB}${BL}ethtool -k $iface${CL} ${YW}# Check offloading status${CL}"
    echo -e "${TAB}${BL}systemctl status disable-nic-offload-$iface.service${CL} ${YW}# Check service status${CL}"
done

exit 0
