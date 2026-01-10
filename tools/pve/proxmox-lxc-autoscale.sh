#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Fabrizio Salmi (fabriziosalmi)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fabriziosalmi/proxmox-lxc-autoscale

function header_info() {
  clear
  cat <<"EOF"
    __   _  ________   ___         __       _____            __   
   / /  | |/ / ____/  /   | __  __/ /_____ / ___/_________ _/ /__ 
  / /   |   / /      / /| |/ / / / __/ __ \\__ \/ ___/ __ `/ / _ \
 / /___/   / /___   / ___ / /_/ / /_/ /_/ /__/ / /__/ /_/ / /  __/
/_____/_/|_\____/  /_/  |_\__,_/\__/\____/____/\___/\__,_/_/\___/ 
                                                                  
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

INSTALL_DIR="/opt/proxmox-lxc-autoscale"
SERVICE_NAME="lxc_autoscale"
REPO_URL="https://github.com/fabriziosalmi/proxmox-lxc-autoscale.git"

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
if ! command -v pct &>/dev/null; then
  msg_error "This script must be run on a Proxmox VE host."
  exit 1
fi

echo -e "\n${YW}LXC AutoScale${CL} - Automatic resource scaling for LXC containers\n"
echo -e "This script will install LXC AutoScale on your Proxmox host."
echo -e "It automatically adjusts CPU and memory allocations based on real-time usage.\n"

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
          cp "${INSTALL_DIR}/config.yaml" "/tmp/lxc_autoscale_config_backup.yaml"
          msg_ok "Configuration backed up to /tmp/lxc_autoscale_config_backup.yaml"
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
msg_info "Cloning LXC AutoScale repository"
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
elif [[ -f "lxc_autoscale/requirements.txt" ]]; then
  pip install --quiet --upgrade pip
  pip install --quiet -r lxc_autoscale/requirements.txt
else
  # Install common dependencies
  pip install --quiet --upgrade pip
  pip install --quiet pyyaml requests
fi
deactivate
msg_ok "Python environment configured"

# Create configuration
msg_info "Setting up configuration"
cd "$INSTALL_DIR"

# Find and setup config file
CONFIG_FILE=""
if [[ -f "lxc_autoscale/config.yaml.example" ]]; then
  CONFIG_FILE="lxc_autoscale/config.yaml"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cp "lxc_autoscale/config.yaml.example" "$CONFIG_FILE"
  fi
elif [[ -f "config.yaml.example" ]]; then
  CONFIG_FILE="config.yaml"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cp "config.yaml.example" "$CONFIG_FILE"
  fi
elif [[ -f "lxc_autoscale/config.yaml" ]]; then
  CONFIG_FILE="lxc_autoscale/config.yaml"
elif [[ -f "config.yaml" ]]; then
  CONFIG_FILE="config.yaml"
fi

# Restore backed up config if exists
if [[ -f "/tmp/lxc_autoscale_config_backup.yaml" ]]; then
  if [[ -n "$CONFIG_FILE" ]]; then
    cp "/tmp/lxc_autoscale_config_backup.yaml" "$CONFIG_FILE"
    rm -f "/tmp/lxc_autoscale_config_backup.yaml"
    msg_ok "Previous configuration restored"
  fi
else
  msg_ok "Default configuration created"
fi

# Determine the main Python script
MAIN_SCRIPT=""
if [[ -f "${INSTALL_DIR}/lxc_autoscale/main.py" ]]; then
  MAIN_SCRIPT="${INSTALL_DIR}/lxc_autoscale/main.py"
elif [[ -f "${INSTALL_DIR}/main.py" ]]; then
  MAIN_SCRIPT="${INSTALL_DIR}/main.py"
elif [[ -f "${INSTALL_DIR}/lxc_autoscale/lxc_autoscale.py" ]]; then
  MAIN_SCRIPT="${INSTALL_DIR}/lxc_autoscale/lxc_autoscale.py"
else
  msg_error "Could not find main Python script"
  exit 1
fi

# Create systemd service
msg_info "Creating systemd service"
cat <<EOF >/etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=Proxmox LXC AutoScale - Automatic resource scaling for LXC containers
Documentation=https://github.com/fabriziosalmi/proxmox-lxc-autoscale
After=network.target lxc.service

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/venv/bin/python3 ${MAIN_SCRIPT}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=false
ProtectSystem=false
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.service >/dev/null 2>&1
msg_ok "Systemd service created and enabled"

# Check LXCFS configuration
header_info
echo ""
echo -e "${YW}╔═══════════════════════════════════════════════════════════════╗${CL}"
echo -e "${YW}║              IMPORTANT: LXCFS CONFIGURATION                   ║${CL}"
echo -e "${YW}╚═══════════════════════════════════════════════════════════════╝${CL}"
echo ""
echo -e "${RD}⚠ IMPORTANT:${CL} LXC AutoScale requires LXCFS to be properly configured."
echo ""
echo -e "You need to check ${BL}/lib/systemd/system/lxcfs.service${CL} for the ${GN}-l${CL} option"
echo -e "which makes loadavg retrieval work correctly."
echo ""
echo -e "Required ExecStart line:"
echo -e "  ${GN}ExecStart=/usr/bin/lxcfs /var/lib/lxcfs -l${CL}"
echo ""
echo -e "After modifying, run:"
echo -e "  ${BL}systemctl daemon-reload && systemctl restart lxcfs${CL}"
echo -e "  Then restart your LXC containers to apply the fix."
echo ""

# Check current LXCFS configuration
LXCFS_SERVICE="/lib/systemd/system/lxcfs.service"
if [[ -f "$LXCFS_SERVICE" ]]; then
  if grep -q "ExecStart=/usr/bin/lxcfs /var/lib/lxcfs -l" "$LXCFS_SERVICE"; then
    echo -e "${CM} LXCFS is already configured correctly with the -l flag."
  elif grep -q "ExecStart=/usr/bin/lxcfs /var/lib/lxcfs$" "$LXCFS_SERVICE"; then
    echo -e "${CROSS} LXCFS is ${RD}NOT${CL} configured with the -l flag!"
    echo ""
    while true; do
      read -p "Would you like to automatically patch LXCFS? (y/n): " yn
      case $yn in
        [Yy]*) 
          sed -i 's|ExecStart=/usr/bin/lxcfs /var/lib/lxcfs$|ExecStart=/usr/bin/lxcfs /var/lib/lxcfs -l|' "$LXCFS_SERVICE"
          systemctl daemon-reload
          systemctl restart lxcfs
          msg_ok "LXCFS patched and restarted"
          echo -e "${YW}Note:${CL} You should restart your LXC containers for the fix to take effect."
          break 
          ;;
        [Nn]*) 
          echo -e "${YW}Please manually configure LXCFS before using LXC AutoScale.${CL}"
          break 
          ;;
        *) echo "Please answer yes or no." ;;
      esac
    done
  fi
fi

echo ""
echo -e "${YW}╔═══════════════════════════════════════════════════════════════╗${CL}"
echo -e "${YW}║                    INSTALLATION COMPLETE                      ║${CL}"
echo -e "${YW}╚═══════════════════════════════════════════════════════════════╝${CL}"
echo ""
echo -e "${GN}LXC AutoScale has been installed successfully!${CL}"
echo ""
echo -e "  ${BL}Installation directory:${CL} ${INSTALL_DIR}"
if [[ -n "$CONFIG_FILE" ]]; then
  echo -e "  ${BL}Configuration file:${CL}     ${INSTALL_DIR}/${CONFIG_FILE}"
fi
echo -e "  ${BL}Service name:${CL}           ${SERVICE_NAME}.service"
echo ""
echo -e "${YW}Commands:${CL}"
echo -e "  Start service:   ${GN}systemctl start ${SERVICE_NAME}${CL}"
echo -e "  Stop service:    ${GN}systemctl stop ${SERVICE_NAME}${CL}"
echo -e "  Check status:    ${GN}systemctl status ${SERVICE_NAME}${CL}"
echo -e "  View logs:       ${GN}journalctl -u ${SERVICE_NAME} -f${CL}"
echo ""
echo -e "${YW}Auto-config (optional):${CL}"
echo -e "  Generate configuration for all LXC containers:"
echo -e "  ${GN}curl -sSL https://raw.githubusercontent.com/fabriziosalmi/proxmox-lxc-autoscale/main/lxc_autoscale/lxc_autoscale_autoconf.sh | bash${CL}"
echo ""

# Ask to start service
while true; do
  read -p "Start the LXC AutoScale service now? (y/n): " yn
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
