#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Fabrizio Salmi (fabriziosalmi)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fabriziosalmi/proxmox-vm-autoscale

function header_info() {
  clear
  cat <<"EOF"
 _    ____  ___   ___         __       _____            __   
| |  / /  |/  /  /   | __  __/ /_____ / ___/_________ _/ /__ 
| | / / /|_/ /  / /| |/ / / / __/ __ \\__ \/ ___/ __ `/ / _ \
| |/ / /  / /  / ___ / /_/ / /_/ /_/ /__/ / /__/ /_/ / /  __/
|___/_/  /_/  /_/  |_\__,_/\__/\____/____/\___/\__,_/_/\___/ 
                                                              
EOF
}

set -eEuo pipefail

# Color definitions
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
CM="${GN}✔${CL}"
CROSS="${RD}✖${CL}"

INSTALL_DIR="/opt/proxmox-vm-autoscale"
SERVICE_NAME="vm_autoscale"
REPO_URL="https://github.com/fabriziosalmi/proxmox-vm-autoscale.git"

function msg_info() {
  local msg="$1"
  echo -e "${BL}[INFO]${CL} ${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${CM} ${msg}"
}

function msg_error() {
  local msg="$1"
  echo -e "${CROSS} ${msg}"
}

header_info

# Check if running on Proxmox host
if ! command -v qm &>/dev/null; then
  msg_error "This script must be run on a Proxmox VE host."
  exit 1
fi

echo -e "\n${YW}VM AutoScale${CL} - Automatic resource scaling for Virtual Machines\n"
echo -e "This script will install VM AutoScale on your Proxmox host."
echo -e "It automatically adjusts VM CPU and RAM based on real-time usage metrics.\n"
echo -e "${YW}Features:${CL}"
echo -e "  • Auto-scaling of VM CPU and RAM based on thresholds"
echo -e "  • Multi-host support via SSH"
echo -e "  • Auto-Hotplug & NUMA configuration"
echo -e "  • Gotify notifications support"
echo -e "  • Billing support for web hosters"
echo ""

while true; do
  read -p "Proceed with installation? (y/n): " yn
  case $yn in
    [Yy]*) break ;;
    [Nn]*) echo "Installation cancelled."; exit 0 ;;
    *) echo "Please answer yes or no." ;;
  esac
done

header_info

# Check for existing installation
if [[ -d "$INSTALL_DIR" ]]; then
  echo -e "\n${YW}Existing installation found at ${INSTALL_DIR}${CL}"
  while true; do
    read -p "Remove existing installation and reinstall? (y/n): " yn
    case $yn in
      [Yy]*) 
        msg_info "Stopping existing service"
        systemctl stop ${SERVICE_NAME}.service 2>/dev/null || true
        systemctl disable ${SERVICE_NAME}.service 2>/dev/null || true
        rm -f /etc/systemd/system/${SERVICE_NAME}.service
        
        # Backup existing config
        if [[ -f "${INSTALL_DIR}/config.yaml" ]]; then
          msg_info "Backing up existing configuration"
          cp "${INSTALL_DIR}/config.yaml" "/tmp/vm_autoscale_config_backup.yaml"
          msg_ok "Configuration backed up to /tmp/vm_autoscale_config_backup.yaml"
        fi
        
        rm -rf "$INSTALL_DIR"
        msg_ok "Existing installation removed"
        break 
        ;;
      [Nn]*) echo "Installation cancelled."; exit 0 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
fi

# Install dependencies
msg_info "Installing dependencies (git, python3, python3-venv)"
apt-get update -qq
apt-get install -y -qq git python3 python3-pip python3-venv >/dev/null 2>&1
msg_ok "Dependencies installed"

# Clone repository
msg_info "Cloning VM AutoScale repository"
git clone --depth 1 -q "$REPO_URL" "$INSTALL_DIR"
msg_ok "Repository cloned to ${INSTALL_DIR}"

# Setup Python virtual environment
msg_info "Setting up Python virtual environment"
cd "$INSTALL_DIR"
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
if [[ -f "requirements.txt" ]]; then
  pip install --quiet --upgrade pip
  pip install --quiet -r requirements.txt
else
  # Install known dependencies for VM autoscale
  pip install --quiet --upgrade pip
  pip install --quiet paramiko pyyaml requests
fi
deactivate
msg_ok "Python environment configured"

# Create/restore configuration
msg_info "Setting up configuration"
cd "$INSTALL_DIR"

CONFIG_FILE="config.yaml"
if [[ -f "/tmp/vm_autoscale_config_backup.yaml" ]]; then
  cp "/tmp/vm_autoscale_config_backup.yaml" "$CONFIG_FILE"
  rm -f "/tmp/vm_autoscale_config_backup.yaml"
  msg_ok "Previous configuration restored"
elif [[ ! -f "$CONFIG_FILE" ]]; then
  if [[ -f "config.yaml.example" ]]; then
    cp "config.yaml.example" "$CONFIG_FILE"
    msg_ok "Default configuration created from example"
  else
    msg_ok "No configuration file found - you'll need to create config.yaml manually"
  fi
else
  msg_ok "Existing configuration preserved"
fi

# Determine the main Python script
MAIN_SCRIPT=""
if [[ -f "${INSTALL_DIR}/autoscale.py" ]]; then
  MAIN_SCRIPT="${INSTALL_DIR}/autoscale.py"
elif [[ -f "${INSTALL_DIR}/main.py" ]]; then
  MAIN_SCRIPT="${INSTALL_DIR}/main.py"
else
  msg_error "Could not find main Python script (autoscale.py or main.py)"
  exit 1
fi

# Create log directory
mkdir -p /var/log/vm_autoscale

# Create systemd service
msg_info "Creating systemd service"
cat <<EOF >/etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=Proxmox VM AutoScale - Automatic resource scaling for Virtual Machines
Documentation=https://github.com/fabriziosalmi/proxmox-vm-autoscale
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/venv/bin/python3 ${MAIN_SCRIPT}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Logging
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.service >/dev/null 2>&1
msg_ok "Systemd service created and enabled"

# Display important information
header_info
echo ""
echo -e "${YW}╔═══════════════════════════════════════════════════════════════╗${CL}"
echo -e "${YW}║              IMPORTANT: VM HOTPLUG REQUIREMENTS               ║${CL}"
echo -e "${YW}╚═══════════════════════════════════════════════════════════════╝${CL}"
echo ""
echo -e "${RD}⚠ IMPORTANT:${CL} For VMs to scale resources live, you must enable:"
echo ""
echo -e "  ${BL}1. NUMA:${CL}           VM > Hardware > Processors > Enable NUMA ☑️"
echo -e "  ${BL}2. CPU Hotplug:${CL}    VM > Options > Hotplug > CPU ☑️"
echo -e "  ${BL}3. Memory Hotplug:${CL} VM > Options > Hotplug > Memory ☑️"
echo ""
echo -e "${GN}Tip:${CL} By default, VM AutoScale will automatically enable hotplug and"
echo -e "     NUMA on managed VMs. Set ${BL}auto_configure_hotplug: false${CL} in config"
echo -e "     to disable this behavior."
echo ""

echo -e "${YW}╔═══════════════════════════════════════════════════════════════╗${CL}"
echo -e "${YW}║                    INSTALLATION COMPLETE                      ║${CL}"
echo -e "${YW}╚═══════════════════════════════════════════════════════════════╝${CL}"
echo ""
echo -e "${GN}VM AutoScale has been installed successfully!${CL}"
echo ""
echo -e "  ${BL}Installation directory:${CL} ${INSTALL_DIR}"
echo -e "  ${BL}Configuration file:${CL}     ${INSTALL_DIR}/${CONFIG_FILE}"
echo -e "  ${BL}Log file:${CL}               /var/log/vm_autoscale.log"
echo -e "  ${BL}Service name:${CL}           ${SERVICE_NAME}.service"
echo ""
echo -e "${YW}Commands:${CL}"
echo -e "  Start service:   ${GN}systemctl start ${SERVICE_NAME}${CL}"
echo -e "  Stop service:    ${GN}systemctl stop ${SERVICE_NAME}${CL}"
echo -e "  Check status:    ${GN}systemctl status ${SERVICE_NAME}${CL}"
echo -e "  View logs:       ${GN}journalctl -u ${SERVICE_NAME} -f${CL}"
echo -e "  View log file:   ${GN}tail -f /var/log/vm_autoscale.log${CL}"
echo ""
echo -e "${YW}Configuration:${CL}"
echo -e "  Edit the configuration file to set up your Proxmox hosts and VMs:"
echo -e "  ${GN}nano ${INSTALL_DIR}/${CONFIG_FILE}${CL}"
echo ""
echo -e "${YW}Required configuration:${CL}"
echo -e "  1. Add your Proxmox host(s) with SSH credentials"
echo -e "  2. Add the VM IDs you want to auto-scale"
echo -e "  3. Adjust scaling thresholds as needed"
echo ""

# Ask to start service
while true; do
  read -p "Start the VM AutoScale service now? (y/n): " yn
  case $yn in
    [Yy]*) 
      systemctl start ${SERVICE_NAME}.service
      msg_ok "Service started"
      echo ""
      systemctl status ${SERVICE_NAME}.service --no-pager
      break 
      ;;
    [Nn]*) 
      echo -e "\nYou can start the service later with: ${GN}systemctl start ${SERVICE_NAME}${CL}"
      break 
      ;;
    *) echo "Please answer yes or no." ;;
  esac
done

echo ""
