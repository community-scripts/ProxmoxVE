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
  msg_info "Waiting for container to initialize..."
  sleep 10
  msg_ok "Container initialized"
  
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
  REDIRECT=""
  QUIET=""
else
  REDIRECT=">/dev/null 2>&1"
  QUIET=">/dev/null 2>&1"
fi

# Update package lists
echo "Updating package lists..." | tee -a "$LOG_FILE" $QUIET
eval "apt update $REDIRECT"

# Install dependencies
echo "Installing dependencies..." | tee -a "$LOG_FILE" $QUIET
eval "apt install -y curl sudo mc apt-transport-https wget gpg xvfb git $REDIRECT"

# Install Chrome with more reliable key handling
echo "Installing Chrome..." | tee -a "$LOG_FILE" $QUIET
# Download the key and verify it downloaded correctly
eval "curl -s https://dl.google.com/linux/linux_signing_key.pub > /tmp/google-key.pub $REDIRECT"
if [ ! -s /tmp/google-key.pub ]; then
  echo "Failed to download Google key, retrying with wget..." | tee -a "$LOG_FILE" $QUIET
  eval "wget -q -O /tmp/google-key.pub https://dl.google.com/linux/linux_signing_key.pub $REDIRECT"
fi

# Verify the key file is not empty and looks valid
if [ ! -s /tmp/google-key.pub ] || ! grep -q "BEGIN PGP PUBLIC KEY BLOCK" /tmp/google-key.pub; then
  echo "Error: Invalid or empty Google signing key" | tee -a "$LOG_FILE" $QUIET
  exit 1
fi

# Import the key
eval "cat /tmp/google-key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg $REDIRECT"

# Add Chrome repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
eval "apt update $REDIRECT"
eval "apt install -y google-chrome-stable $REDIRECT"

# Install UV Package Manager
echo "Installing UV Package Manager..." | tee -a "$LOG_FILE" $QUIET
eval "curl -LsSf https://astral.sh/uv/install.sh | sh $REDIRECT"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'source "$HOME/.local/bin/env"' >> ~/.bashrc
eval "source $HOME/.local/bin/env $REDIRECT || true"

# Clone Byparr
echo "Installing Byparr..." | tee -a "$LOG_FILE" $QUIET
eval "git clone https://github.com/ThePhaseless/Byparr.git /opt/byparr $REDIRECT"
cd /opt/byparr
eval "source $HOME/.local/bin/env $REDIRECT || true"
eval "uv sync --group test $REDIRECT"

# Create service
echo "Creating Byparr service..." | tee -a "$LOG_FILE" $QUIET
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
eval "systemctl daemon-reload $REDIRECT"
eval "systemctl enable --now byparr.service $REDIRECT"

# Configure SSH for root access
echo "Setting up system access..." | tee -a "$LOG_FILE" $QUIET
eval "sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config $REDIRECT"
eval "sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config $REDIRECT"
eval "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config $REDIRECT"
# Add these lines explicitly if sed fails
eval "grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config $REDIRECT || echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config"
eval "grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config $REDIRECT || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config"
eval "systemctl restart sshd $REDIRECT"

# Set root password directly
echo "Setting root password..." | tee -a "$LOG_FILE" $QUIET
eval "passwd --delete root $REDIRECT"
eval "echo -e 'root\nroot' | passwd root $REDIRECT"
eval "echo 'root:root' | chpasswd $REDIRECT"

# Cleanup
echo "Cleaning up..." | tee -a "$LOG_FILE" $QUIET
eval "rm -f /tmp/google-key.pub $REDIRECT"
eval "apt-get -y autoremove $REDIRECT"
eval "apt-get -y autoclean $REDIRECT"

echo "Byparr installation completed successfully at $(date)" | tee -a "$LOG_FILE" $QUIET
EOF

  # Copy the script to the container
  pct push "$CTID" /tmp/byparr-install-script.sh /tmp/byparr-install-script.sh
  pct exec "$CTID" -- chmod +x /tmp/byparr-install-script.sh
  
  # Execute the installation script inside the container
  msg_info "Running installation script"
  
  if [ "$VERB" = "1" ]; then
    # Verbose mode: Show detailed output
    pct exec "$CTID" -- bash -c "export VERBOSE=$VERB; /tmp/byparr-install-script.sh"
  else
    # Non-verbose mode: Hide detailed output
    pct exec "$CTID" -- bash -c "export VERBOSE=$VERB; /tmp/byparr-install-script.sh" >/dev/null 2>&1
  fi
  
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
pct exec "$CTID" -- bash -c "passwd --delete root && echo -e 'root\nroot' | passwd root" >/dev/null 2>&1
pct exec "$CTID" -- bash -c "echo 'root:root' | chpasswd" >/dev/null 2>&1
# Add verification
pct exec "$CTID" -- bash -c "grep -q '^root:' /etc/shadow || echo 'ERROR: Root password not set correctly'" >/dev/null 2>&1
msg_ok "Root password set"

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"
echo -e "${INFO}${YW} Container IP address: ${IP}${CL}"
echo -e "${INFO}${YW} Default login credentials:${CL}"
echo -e "${TAB}${YW}Username: root${CL}"
echo -e "${TAB}${YW}Password: root${CL}"