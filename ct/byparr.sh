#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tanujdargan/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: tanujdargan
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

set -e #terminate script if it fails a command

APP="Byparr"
var_tags="arr,community-script"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

# Initialize VERB variable with default value
VERB="${VERB:-0}"

# Define output redirection based on verbose flag
if [ "$VERB" = "1" ]; then
  REDIRECT=""
else
  REDIRECT=">/dev/null 2>&1"
fi

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/byparr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating Byparr"
    cd /opt/byparr
    eval "git pull $REDIRECT"
    eval "uv sync --group test $REDIRECT"
    systemctl restart byparr.service
    msg_ok "Updated Byparr"
    exit
}

# Override the normal build_container function with custom logic
function build_container() {
  if [ "$CT_TYPE" == "1" ]; then
    FEATURES="keyctl=1,nesting=1"
  else
    FEATURES="nesting=1"
  fi

  TEMP_DIR=$(mktemp -d)
  pushd $TEMP_DIR >/dev/null
  
  if [ "$var_os" == "alpine" ]; then
    export FUNCTIONS_FILE_PATH="$(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/alpine-install.func)"
  else
    export FUNCTIONS_FILE_PATH="$(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)"
  fi
  
  export RANDOM_UUID="$RANDOM_UUID"
  export CACHER="$APT_CACHER"
  export CACHER_IP="$APT_CACHER_IP"
  export tz="$timezone"
  export DISABLEIPV6="$DISABLEIP6"
  export APPLICATION="$APP"
  export app="$NSAPP"
  export PASSWORD="$PW"
  export VERBOSE="$VERB"
  export SSH_ROOT="${SSH}"
  export SSH_AUTHORIZED_KEY
  export CTID="$CT_ID"
  export CTTYPE="$CT_TYPE"
  export PCT_OSTYPE="$var_os"
  export PCT_OSVERSION="$var_version"
  export PCT_DISK_SIZE="$DISK_SIZE"
  export PCT_OPTIONS="
    -features $FEATURES
    -hostname $HN
    -tags $TAGS
    $SD
    $NS
    -net0 name=eth0,bridge=$BRG$MAC,ip=$NET$GATE$VLAN$MTU
    -onboot 1
    -cores $CORE_COUNT
    -memory $RAM_SIZE
    -unprivileged $CT_TYPE
    $PW
  "
  
  # Create the container
  bash -c "$(wget -qLO - https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/create_lxc.sh)" || exit $?

  LXC_CONFIG=/etc/pve/lxc/${CTID}.conf
  if [ "$CT_TYPE" == "0" ]; then
    cat <<EOF >>$LXC_CONFIG
# USB passthrough
lxc.cgroup2.devices.allow: a
lxc.cap.drop:
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 189:* rwm
lxc.mount.entry: /dev/serial/by-id  dev/serial/by-id  none bind,optional,create=dir
lxc.mount.entry: /dev/ttyUSB0       dev/ttyUSB0       none bind,optional,create=file
lxc.mount.entry: /dev/ttyUSB1       dev/ttyUSB1       none bind,optional,create=file
lxc.mount.entry: /dev/ttyACM0       dev/ttyACM0       none bind,optional,create=file
lxc.mount.entry: /dev/ttyACM1       dev/ttyACM1       none bind,optional,create=file
EOF
  fi

  # Start the container
  msg_info "Starting LXC Container"
  pct start "$CTID"
  msg_ok "Started LXC Container"

  # Wait for container to fully start
  echo "Waiting for container to initialize..."
  sleep 10
  
  # Create the installation script file
  cat > /tmp/byparr-install-script.sh <<'EOF'
#!/usr/bin/env bash

# Byparr Installation Script
# Based on your manual installation steps

# Set up logging
LOG_FILE="/var/log/byparr-install.log"
echo "Starting Byparr installation at $(date)" > "$LOG_FILE"

# Determine output redirection based on VERBOSE environment variable
if [ "$VERBOSE" = "1" ]; then
  log() {
    echo "$1" | tee -a "$LOG_FILE"
  }
else
  log() {
    echo "$1" >> "$LOG_FILE"
  }
fi

# Function for executing commands with proper output handling
run_cmd() {
  if [ "$VERBOSE" = "1" ]; then
    eval "$1"
  else
    eval "$1 >/dev/null 2>&1"
  fi
}

# Update package lists
log "Updating package lists..."
run_cmd "apt update"

# Install dependencies
log "Installing dependencies..."
run_cmd "apt install -y curl sudo mc apt-transport-https wget gpg xvfb git"

# Install Chrome with more reliable key handling
log "Installing Chrome..."
# Download the key and verify it downloaded correctly
run_cmd "curl -s https://dl.google.com/linux/linux_signing_key.pub > /tmp/google-key.pub"
if [ ! -s /tmp/google-key.pub ]; then
  log "Failed to download Google key, retrying with wget..."
  run_cmd "wget -q -O /tmp/google-key.pub https://dl.google.com/linux/linux_signing_key.pub"
fi

# Verify the key file is not empty and looks valid
if [ ! -s /tmp/google-key.pub ] || ! grep -q "BEGIN PGP PUBLIC KEY BLOCK" /tmp/google-key.pub; then
  log "Error: Invalid or empty Google signing key"
  exit 1
fi

# Import the key
run_cmd "cat /tmp/google-key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg"

# Add Chrome repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
run_cmd "apt update"
run_cmd "apt install -y google-chrome-stable"

# Install UV Package Manager
log "Installing UV Package Manager..."
run_cmd "curl -LsSf https://astral.sh/uv/install.sh | sh"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'source "$HOME/.local/bin/env"' >> ~/.bashrc
run_cmd "source $HOME/.local/bin/env || true"

# Clone Byparr
log "Installing Byparr..."
run_cmd "git clone https://github.com/ThePhaseless/Byparr.git /opt/byparr"
cd /opt/byparr
run_cmd "source $HOME/.local/bin/env || true"
run_cmd "uv sync --group test"

# Create service
log "Creating Byparr service..."
cat <<INNEREOF >/etc/systemd/system/byparr.service
[Unit]
Description=Byparr
After=network.target
[Service]
SyslogIdentifier=byparr
Restart=always
RestartSec=5
Type=simple
Environment="LOG_LEVEL=info"
Environment="CAPTCHA_SOLVER=none"
Environment="PATH=/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
WorkingDirectory=/opt/byparr
ExecStart=/bin/bash -c "source /root/.local/bin/env && cd /opt/byparr && uv sync && ./cmd.sh"
TimeoutStopSec=60
[Install]
WantedBy=multi-user.target
INNEREOF

# Enable and start the service
run_cmd "systemctl daemon-reload"
run_cmd "systemctl enable --now byparr.service"

# Configure SSH for root access
log "Setting up system access..."
run_cmd "sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config"
run_cmd "sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config"
run_cmd "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config"
# Add these lines explicitly if sed fails
run_cmd "grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config"
run_cmd "grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config"
run_cmd "systemctl restart sshd"

# Set root password directly
log "Setting root password..."
run_cmd "passwd --delete root"
run_cmd "echo -e 'root\nroot' | passwd root"
run_cmd "echo 'root:root' | chpasswd"

# Cleanup
log "Cleaning up..."
run_cmd "rm -f /tmp/google-key.pub"
run_cmd "apt-get -y autoremove"
run_cmd "apt-get -y autoclean"

log "Byparr installation completed successfully at $(date)"
EOF

  # Copy the script to the container
  pct push "$CTID" /tmp/byparr-install-script.sh /tmp/byparr-install-script.sh
  pct exec "$CTID" -- chmod +x /tmp/byparr-install-script.sh
  
  # Execute the installation script inside the container
  msg_info "Running installation script"
  pct exec "$CTID" -- bash -c "export VERBOSE=$VERB; /tmp/byparr-install-script.sh"
  msg_ok "Installation script completed"
}

start
build_container
description

# Get IP address explicitly
IP=$(pct exec "$CTID" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
if [ -z "$IP" ]; then
  # Try again if IP is empty
  sleep 5
  IP=$(pct exec "$CTID" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
fi

# Set password just to be sure
msg_info "Setting root password"
pct exec "$CTID" -- bash -c "passwd --delete root && echo -e 'root\nroot' | passwd root"
pct exec "$CTID" -- bash -c "echo 'root:root' | chpasswd"
# Add verification
pct exec "$CTID" -- bash -c "grep -q '^root:' /etc/shadow || echo 'ERROR: Root password not set correctly'"
msg_ok "Root password set"

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"
echo -e "${INFO}${YW} Container IP address: ${IP}${CL}"
echo -e "${INFO}${YW} Default login credentials:${CL}"
echo -e "${TAB}${YW}Username: root${CL}"
echo -e "${TAB}${YW}Password: root${CL}"