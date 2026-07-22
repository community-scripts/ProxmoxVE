#!/usr/bin/env bash
# MoAI — Modular AI Platform Container Setup
# Creates a Debian LXC container optimized for the MoAI platform

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: f4br1c3 / 41-4g3nt
# License: MIT | https://github.com/41-4g3nt/MoAI/raw/main/LICENSE

APP="MoAI"
var_tags="${var_tags:-ai;platform;modular}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-40}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  
  check_container_storage
  check_container_resources

  msg_info "Updating base system"
  $STD apt update && $STD apt upgrade -y
  msg_ok "Base system updated"

  # Update Docker if installed
  if command -v docker &>/dev/null; then
    msg_info "Updating Docker packages"
    $STD curl -fsSL https://get.docker.com | sh
    msg_ok "Docker updated"
  fi

  # Update MoAI platform
  if [ -d /opt/moai ]; then
    cd /opt/moai && git pull || true
    msg_ok "MoAI platform updated"
  fi

  msg_ok "Updated successfully!"
  exit 0
}

function setup_moai() {
  header_info

  # ── Step 1: Install base dependencies ───────────────────────
  msg_info "Installing base system packages"
  
  $STD apt update
  $STD apt install -y \
    curl wget git vim nano htop tmux \
    ca-certificates gnupg lsb-release \
    apt-transport-https software-properties-common \
    python3 python3-pip python3-venv \
    docker.io docker-compose-plugin
  
  # Install additional tools for AI workloads
  $STD apt install -y \
    build-essential cmake pkg-config libjpeg-dev libpng-dev \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev

  msg_ok "Base packages installed"

  # ── Step 2: Configure Docker ────────────────────────────────
  msg_info "Configuring Docker"
  
  $STD systemctl enable docker
  $STD systemctl start docker
  
  # Add current user to docker group (non-root access)
  if id -nG "$USER" 2>/dev/null | grep -qw docker; then
    msg_ok "User '$USER' already in docker group"
  else
    $STD usermod -aG docker "$USER"
    msg_ok "Added '$USER' to docker group"
  fi

  # Configure Docker daemon for optimal performance
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json << 'EOF'
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF
  
  $STD systemctl restart docker
  msg_ok "Docker configured"

  # ── Step 3: GPU Detection & Configuration ───────────────────
  if command -v lspci &>/dev/null; then
    PCI_INFO=$(lspci 2>/dev/null)
    
    # NVIDIA GPU detection
    if echo "$PCI_INFO" | grep -qi "nvidia"; then
      msg_info "NVIDIA GPU detected — installing drivers"
      
      $STD apt install -y nvidia-driver-libs nvidia-cuda-toolkit
      
      # Configure NVIDIA container runtime
      $STD curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        $STD gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
      
      $STD curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' > /etc/apt/sources.list.d/nvidia-container-toolkit.list
      
      $STD apt update
      $STD apt install -y nvidia-container-toolkit
      $STD nvidia-ctk runtime configure --runtime=docker
      $STD systemctl restart docker
      
      msg_ok "NVIDIA drivers and container toolkit installed"
    fi

    # AMD GPU detection
    if echo "$PCI_INFO" | grep -qi "amd\|ati"; then
      msg_info "AMD GPU detected — configuring ROCm"
      
      # Install ROCm packages (Debian 13+)
      $STD apt install -y rocm-dev rocminfo
      
      # Configure AMD container runtime
      mkdir -p /etc/rocm
      cat > /etc/rocm/core.conf << 'EOF'
[core]
ignore_devlist = true
EOF

      msg_ok "AMD ROCm configured"
    fi
  else
    msg_warn "No GPU detected or lspci not available — continuing without GPU support"
  fi

  # ── Step 4: Install MoAI Platform ───────────────────────────
  msg_info "Installing MoAI platform"
  
  mkdir -p /opt/moai
  cd /opt/moai
  
  # Clone MoAI repository
  if [ ! -d ".git" ]; then
    $STD git clone https://github.com/41-4g3nt/MoAI.git . || {
      msg_error "Failed to clone MoAI repository"
      exit 1
    }
  else
    cd /opt/moai && $STD git pull || true
  fi

  # Create data directories for services
  mkdir -p /opt/moai/data/{searxng,ollama,mem0,qdrant}
  
  # Set proper permissions
  chown -R "$USER:$USER" /opt/moai
  chmod +x /opt/moai/*.sh 2>/dev/null || true

  msg_ok "MoAI platform installed to /opt/moai"

  # ── Step 5: Create systemd service for MoAI ────────────────
  msg_info "Creating systemd service for MoAI"
  
  cat > /etc/systemd/system/moai.service << EOF
[Unit]
Description=MoAI Platform Service
After=docker.service network-online.target
Wants=docker.service network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/moai
ExecStartPre=/usr/bin/docker compose -f docker-compose.base.yml up -d || true
ExecStart=/bin/bash -c 'cd /opt/moai && ./hub.py setup'
ExecStop=/usr/bin/docker compose -f docker-compose.base.yml down
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

  $STD systemctl daemon-reload
  $STD systemctl enable moai.service
  
  msg_ok "Systemd service created"

  # ── Step 6: Configure firewall (if ufw available) ───────────
  if command -v ufw &>/dev/null; then
    msg_info "Configuring firewall"
    
    $STD ufw allow ssh
    $STD ufw allow http
    $STD ufw allow https
    
    # MoAI service ports (configurable)
    $STD ufw allow 3000/tcp comment 'MoAI Open WebUI'
    $STD ufw allow 8080/tcp comment 'MoAI SearXNG'
    
    $STD ufw enable || true
    msg_ok "Firewall configured"
  fi

  # ── Step 7: Setup motd and access info ─────────────────────
  msg_info "Configuring access information"
  
  cat > /etc/profile.d/moai-info.sh << EOF
export MOAI_HOME="/opt/moai"
export PATH="\$MOAI_HOME/bin:\$PATH"
EOF

  # Update MOTD with MoAI info
  cat > /etc/motd << EOF

${GN}╔══════════════════════════════════════════════════════════╗${CL}
${GN}║              MoAI Platform — Setup Complete!             ║${CL}
${GN}╚══════════════════════════════════════════════════════════╝${CL}

${YW}Platform Home:${CL}    /opt/moai
${YW}Documentation:${CL}    https://github.com/41-4g3nt/MoAI
${YW}Next Steps:${CL}       cd /opt/moai && ./hub.py setup

${YW}Services will start automatically on boot.${CL}
${GN}╔══════════════════════════════════════════════════════════╗${CL}

EOF

  msg_ok "Access information configured"

  # ── Step 8: Verify installation ─────────────────────────────
  msg_info "Verifying installation"
  
  local checks_passed=0
  local total_checks=5
  
  # Check Docker
  if command -v docker &>/dev/null && docker --version &>/dev/null; then
    msg_ok "✓ Docker installed: $(docker --version 2>/dev/null | awk '{print $3}')"
    ((checks_passed++))
  else
    msg_error "✗ Docker not working"
  fi
  
  # Check Python
  if command -v python3 &>/dev/null; then
    msg_ok "✓ Python3 installed: $(python3 --version 2>&1)"
    ((checks_passed++))
  else
    msg_error "✗ Python3 not found"
  fi
  
  # Check MoAI directory
  if [ -d /opt/moai ] && [ -f /opt/moai/README.md ]; then
    msg_ok "✓ MoAI platform files present"
    ((checks_passed++))
  else
    msg_error "✗ MoAI files missing"
  fi
  
  # Check Docker group membership
  if id -nG "$USER" 2>/dev/null | grep -qw docker; then
    msg_ok "✓ User '$USER' in docker group"
    ((checks_passed++))
  else
    msg_warn "⚠ User not in docker group — log out and back in"
  fi
  
  # Check systemd service
  if systemctl is-enabled moai.service &>/dev/null; then
    msg_ok "✓ MoAI service enabled on boot"
    ((checks_passed++))
  else
    msg_warn "⚠ MoAI service not enabled"
  fi

  echo ""
  msg_info "Verification: $checks_passed/$total_checks checks passed"
}

start
setup_moai
build_container
description

msg_ok "MoAI Platform setup completed successfully!\n"
echo -e "${CREATING}${GN}MoAI platform has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000 (Open WebUI)${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080 (SearXNG Search)${CL}"
echo ""
echo -e "${INFO}${YW}Next steps:${CL}"
echo -e "  ${CYAN}1.${CL} SSH into the container: ssh root@${IP}"
echo -e "  ${CYAN}2.${CL} Run MoAI setup:        cd /opt/moai && ./hub.py setup"
echo -e "  ${CYAN}3.${CL} Configure your AI platform"
