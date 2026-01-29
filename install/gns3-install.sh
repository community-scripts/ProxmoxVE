#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Yumgi
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/GNS3/gns3-server

# Import Functions and Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# =============================================================================
# DEPENDENCIES
# =============================================================================
msg_info "Installing Dependencies"
$STD apt-get install -y \
  software-properties-common \
  gnupg \
  apt-transport-https \
  ca-certificates
msg_ok "Installed Dependencies"

# =============================================================================
# GNS3 SERVER INSTALLATION
# =============================================================================
msg_info "Adding GNS3 PPA Repository"
$STD add-apt-repository -y ppa:gns3/ppa
$STD apt-get update
msg_ok "Added GNS3 Repository"

msg_info "Installing GNS3 Server"
# Determine version to install
GNS3_VERSION="${GNS3_VERSION:-latest}"

if [[ "$GNS3_VERSION" == "latest" ]]; then
  msg_info "Installing latest GNS3 Server version"
  $STD apt-get install -y gns3-server
else
  msg_info "Installing GNS3 Server version ${GNS3_VERSION}"
  # Find exact package version
  PACKAGE_VERSION=$(apt-cache madison gns3-server | grep "$GNS3_VERSION" | head -1 | awk '{print $3}')

  if [[ -z "$PACKAGE_VERSION" ]]; then
    msg_error "Version ${GNS3_VERSION} not found in repository"
    msg_info "Available versions:"
    apt-cache madison gns3-server | awk '{print $3}' | head -5
    exit 1
  fi

  $STD apt-get install -y gns3-server=${PACKAGE_VERSION}
  $STD apt-mark hold gns3-server
  msg_ok "Installed GNS3 Server ${GNS3_VERSION} (package held)"
fi

# Install QEMU/KVM for emulation
$STD apt-get install -y \
  qemu-kvm \
  qemu-utils \
  libvirt-daemon-system \
  virtinst \
  bridge-utils \
  uml-utilities
msg_ok "Installed GNS3 Server and QEMU"

# =============================================================================
# DOCKER INSTALLATION (for Docker appliances)
# =============================================================================
msg_info "Installing Docker"
setup_docker
msg_ok "Installed Docker"

# =============================================================================
# GNS3 CONFIGURATION
# =============================================================================
get_lxc_ip

msg_info "Configuring GNS3 Server"
# Create GNS3 directories
mkdir -p /opt/gns3/{images,projects,appliances,configs}
mkdir -p /etc/gns3

# Configure GNS3 to listen on all interfaces
cat >/etc/gns3/gns3_server.conf <<EOF
[Server]
host = 0.0.0.0
port = 3080
path = /opt/gns3
images_path = /opt/gns3/images
projects_path = /opt/gns3/projects
appliances_path = /opt/gns3/appliances
configs_path = /opt/gns3/configs
report_errors = True

[Qemu]
enable_hardware_acceleration = True
require_hardware_acceleration = True
EOF

# Set proper permissions
chown -R root:root /opt/gns3
chmod -R 755 /opt/gns3
msg_ok "Configured GNS3 Server"

# =============================================================================
# SERVICE CREATION
# =============================================================================
msg_info "Creating GNS3 Service"
cat >/etc/systemd/system/gns3.service <<EOF
[Unit]
Description=GNS3 Server
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/gns3server --local
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q --now gns3.service
msg_ok "Created GNS3 Service"

# =============================================================================
# CLEANUP & FINALIZATION
# =============================================================================
motd_ssh
customize
cleanup_lxc
