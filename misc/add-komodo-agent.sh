#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Arnaud Dartois (Nonobis)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"

#       #     #  #####     #    #                                          #                               
#        #   #  #     #    #   #   ####  #    #  ####  #####   ####       # #    ####  ###### #    # ##### 
#         # #   #          #  #   #    # ##  ## #    # #    # #    #     #   #  #    # #      ##   #   #   
#          #    #          ###    #    # # ## # #    # #    # #    #    #     # #      #####  # #  #   #   
#         # #   #          #  #   #    # #    # #    # #    # #    #    ####### #  ### #      #  # #   #   
#        #   #  #     #    #   #  #    # #    # #    # #    # #    #    #     # #    # #      #   ##   #   
####### #     #  #####     #    #  ####  #    #  ####  #####   ####     #     #  ####  ###### #    #   #   

EOF
}

clear
header_info
APP="LXC Komodo Agent Installer"
hostname=$(hostname)
CRON_JOB="/etc/cron.d/komodo_agent"
LOG_FILE="/var/log/komodo_agent_install.log"
SCRIPT_URL="https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py"

msg_info() {
  echo -ne "➤ $1..."
}

msg_ok() {
  echo -e "✔ $1"
}

msg_error() {
  echo -e "✖ $1"
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

# Ask the user if they want to add a cron job for automatic installation
while true; do
  read -p "Do you want to schedule automatic reinstallation via cron? (y/n): " cron_yn
  case $cron_yn in
  [Yy]*)
    # Check if cron service is running
    if ! systemctl is-active --quiet cron; then
      msg_error "Cron service is not running. Start it first before scheduling."
      exit 1
    fi

    # Check if the cron job already exists
    if [ -f "$CRON_JOB" ]; then
      msg_ok "Cron job already exists at $CRON_JOB"
    else
      msg_info "Creating cron job for automatic installation"
      echo "0 */12 * * * root wget -qLO - $SCRIPT_URL | bash >> $LOG_FILE 2>&1" > "$CRON_JOB"
      chmod 644 "$CRON_JOB"
      systemctl restart cron
      msg_ok "Cron job added: Runs every 12 hours"
    fi
    break
    ;;
  [Nn]*)
    msg_info "Skipping cron job setup."
    break
    ;;
  *) msg_error "Please answer yes or no." ;;
  esac
done
