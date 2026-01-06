#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://home.tdarr.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check

# =============================================================================
# Hardware Acceleration Detection
# =============================================================================
# NVIDIA version is passed from the ct/tdarr.sh script via a file.
# Intel iGPU is detected directly via /dev/dri.

ENABLE_NVIDIA="no"
ENABLE_INTEL="no"
NVIDIA_HOST_VERSION=""

# Check for NVIDIA (Auto-detect via /proc or passed file)
if [ -f /tmp/nvidia_host_version ]; then
    NVIDIA_HOST_VERSION=$(cat /tmp/nvidia_host_version)
    rm -f /tmp/nvidia_host_version
elif [ -f /proc/driver/nvidia/version ]; then
    NVIDIA_HOST_VERSION=$(grep "NVRM version:" /proc/driver/nvidia/version | awk '{print $8}')
fi

if [ -n "$NVIDIA_HOST_VERSION" ]; then
    msg_info "NVIDIA GPU configured (Host Driver: ${NVIDIA_HOST_VERSION})"
    ENABLE_NVIDIA="yes"
fi

# Check for Intel/AMD iGPU (via /dev/dri)
if [ -d /dev/dri ]; then
    read -r -p "Intel/AMD iGPU detected (/dev/dri). Install VA-API drivers? <y/N> " prompt
    if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
        ENABLE_INTEL="yes"
    fi
fi

# =============================================================================
# NVIDIA Repository Configuration (Debian only)
# =============================================================================

if [ "$ENABLE_NVIDIA" == "yes" ] && [ -f /etc/debian_version ]; then
    msg_info "Configuring NVIDIA Repository"
    
    # Enable non-free components
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then
        sed -i -E 's/Components: (.*) main$/Components: \1 main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources
    fi
    
    # Pin NVIDIA repo higher than Debian's
    cat <<EOF > /etc/apt/preferences.d/nvidia-cuda-pin
Package: *
Pin: origin developer.download.nvidia.com
Pin-Priority: 1001
EOF

    # Add NVIDIA CUDA repository if not present
    if [ ! -f /usr/share/keyrings/cuda-archive-keyring.gpg ]; then
        msg_info "Adding NVIDIA CUDA Repository"
        temp_deb="$(mktemp)"
        curl -fsSL -o "$temp_deb" https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
        $STD dpkg -i "$temp_deb"
        rm -f "$temp_deb"
        msg_ok "Added NVIDIA CUDA Repository"
    fi
    
    msg_ok "Configured NVIDIA Repository"
fi

update_os

# =============================================================================
# Dependencies Installation
# =============================================================================

msg_info "Installing Dependencies"
$STD apt install -y handbrake-cli
NVIDIA_PKGS=""
OTHER_PKGS=""

if [ -f /etc/debian_version ]; then
    if [ "$ENABLE_NVIDIA" == "yes" ] && [ -n "$NVIDIA_HOST_VERSION" ]; then
        # NVIDIA packages for hardware transcoding (version must match host)
        NVIDIA_PKGS="libcuda1=${NVIDIA_HOST_VERSION}* libnvcuvid1=${NVIDIA_HOST_VERSION}* libnvidia-encode1=${NVIDIA_HOST_VERSION}* libnvidia-ml1=${NVIDIA_HOST_VERSION}*"
        msg_info "Matching container NVIDIA packages to version: ${NVIDIA_HOST_VERSION}"
    fi

    if [ "$ENABLE_INTEL" == "yes" ]; then
        OTHER_PKGS="$OTHER_PKGS intel-media-va-driver-non-free vainfo"
        msg_info "Added Intel VA-API drivers"
    fi
fi

# Install other hardware acceleration packages
if [ -n "$OTHER_PKGS" ]; then
    $STD apt install -y $OTHER_PKGS
fi

# Install NVIDIA packages with fallback
if [ -n "$NVIDIA_PKGS" ]; then
    if ! $STD apt install -y --no-install-recommends $NVIDIA_PKGS 2>/dev/null; then
        msg_warn "Version-pinned NVIDIA install failed (host may use different repo)."
        msg_warn "Trying unpinned install - version mismatch may occur."
        # Try without version pinning as fallback
        NVIDIA_PKGS_UNPINNED="libcuda1 libnvcuvid1 libnvidia-encode1 libnvidia-ml1"
        $STD apt install -y --no-install-recommends $NVIDIA_PKGS_UNPINNED || msg_warn "NVIDIA package install failed. GPU acceleration may not work."
    fi
fi

if [ "$ENABLE_NVIDIA" == "yes" ]; then
    # Try to install nvidia-smi but don't fail if it's missing (it's for user verification)
    $STD apt install -y --no-install-recommends nvidia-smi || msg_info "nvidia-smi was not installed (optional)"
fi

msg_ok "Installed Dependencies"

# =============================================================================
# Tdarr Installation
# =============================================================================

msg_info "Installing Tdarr"
mkdir -p /opt/tdarr
cd /opt/tdarr
RELEASE=$(curl -fsSL https://f000.backblazeb2.com/file/tdarrs/versions.json | grep -oP '(?<="Tdarr_Updater": ")[^"]+' | grep linux_x64 | head -n 1)
curl -fsSL "$RELEASE" -o Tdarr_Updater.zip
$STD unzip Tdarr_Updater.zip
chmod +x Tdarr_Updater
$STD ./Tdarr_Updater
rm -rf /opt/tdarr/Tdarr_Updater.zip
msg_ok "Installed Tdarr"

setup_hwaccel

# =============================================================================
# Service Configuration
# =============================================================================

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tdarr-server.service
[Unit]
Description=Tdarr Server Daemon
After=network.target
# Enable if using ZFS, edit and enable if other FS mounting is required to access directory
#Requires=zfs-mount.service

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/opt/tdarr/Tdarr_Server
ExecStartPre=/opt/tdarr/Tdarr_Updater
ExecStart=/opt/tdarr/Tdarr_Server/Tdarr_Server
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/tdarr-node.service
[Unit]
Description=Tdarr Node Daemon
After=network.target
Requires=tdarr-server.service

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/opt/tdarr/Tdarr_Node
ExecStart=/opt/tdarr/Tdarr_Node/Tdarr_Node
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now -q tdarr-server tdarr-node
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
