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
SCRIPT_URL="https://github.com/community-scripts/ProxmoxVE/blob/main/misc/add-komodo-agent.sh"

msg_info() {
  echo -ne "➤ $1..."
}

msg_ok() {
  echo -e "✔ $1"
}

msg_error() {
  echo -e "✖ $1"
}

# Enable debug mode if requested
if [[ "$1" == "--debug" ]]; then
  set -x
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

# Check Proxmox version
if ! pveversion | grep -Eq "pve-manager/8\.[0-9]+"; then
  msg_error "This version of Proxmox Virtual Environment is not supported"
  msg_error "⚠ Requires Proxmox Virtual Environment Version 8.0 or later."
  exit
fi

# Fetch the list of LXC containers
msg_info "Fetching LXC container list"
vmid_list=$(pct list 2>/dev/null | awk 'NR>1 {print $1}')
if [[ -z "$vmid_list" ]]; then
  msg_error "No LXC containers found."
  exit 1
fi
msg_ok "LXC container list retrieved"

# Install Komodo Agent on each container
for vmid in $vmid_list; do
  msg_info "Installing Komodo Agent on LXC $vmid"
  
  # Run the command and capture the error if it fails
  OUTPUT=$(pct exec "$vmid" -- bash -c "curl -sSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3" 2>&1)
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    msg_ok "Komodo Agent installed on LXC $vmid"
  else
    msg_error "Failed to install Komodo Agent on LXC $vmid"
    echo "Error log for LXC $vmid:" >> "$LOG_FILE"
    echo "$OUTPUT" >> "$LOG_FILE"
  fi
done

echo -e "\n${APP} installation completed successfully!"

# Ask the user if they want to add a cron job
while true; do
  read -p "Do you want to schedule automatic reinstallation via cron? (y/n): " cron_yn
  case $cron_yn in
  [Yy]*)
    # Check if the cron job already exists
    if [ -f "$CRON_JOB" ]; then
      msg_ok "Cron job already exists at $CRON_JOB"
    else
      msg_info "Creating cron job for automatic installation"
      
      # Add the cron job to run the script every 12 hours (adjustable)
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
