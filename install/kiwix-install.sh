#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tewalds
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kiwix/kiwix-tools

export LC_ALL=C  # Disable Perl locale warnings.
export DEBIAN_FRONTEND=noninteractive
export DISABLE_LOCALE="y"

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
# Kiwix-tools binaries are statically compiled and have minimal dependencies.
# Only libharfbuzz0b and fontconfig are needed for rendering.

msg_info "Installing Dependencies"
$STD apt-get install -y \
  libharfbuzz0b \
  fontconfig
msg_ok "Installed Dependencies"

# =============================================================================
# DOWNLOAD & DEPLOY APPLICATION
# =============================================================================
# Kiwix distributes pre-built binaries from download.kiwix.org
# NOT from GitHub releases (GitHub only has source code)

msg_info "Downloading Kiwix-Tools"

# Detect architecture
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
  i386)  KIWIX_ARCH="i586" ;;
  amd64) KIWIX_ARCH="x86_64" ;;
  arm64) KIWIX_ARCH="aarch64" ;;
  *) msg_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Download from official Kiwix download server
# URL: https://download.kiwix.org/release/kiwix-tools/
cd /tmp
DOWNLOAD_URL="https://download.kiwix.org/release/kiwix-tools/kiwix-tools_linux-${KIWIX_ARCH}.tar.gz"
$STD wget -O kiwix-tools.tar.gz "$DOWNLOAD_URL"
msg_ok "Downloaded Kiwix-Tools"

msg_info "Installing Kiwix Binaries"
$STD tar -xzf kiwix-tools.tar.gz
# Find the extracted directory
KIWIX_DIR=$(find . -maxdepth 1 -type d -name "kiwix-tools_linux-${KIWIX_ARCH}*" | head -1)
if [ -z "$KIWIX_DIR" ]; then
  msg_error "Failed to find extracted Kiwix directory"
  exit 1
fi
cd "$KIWIX_DIR"
cp kiwix-* /usr/local/bin/
chmod +x /usr/local/bin/kiwix-*
cd /tmp
rm -rf kiwix-tools.tar.gz kiwix-tools_linux-*
msg_ok "Installed Kiwix Binaries"

# =============================================================================
# CREATE SYSTEMD SERVICE
# =============================================================================
# The service will serve all .zim files from /data (bind-mounted from host).
# Port 8080 is used by default.

msg_info "Creating Kiwix Service"
cat <<'EOF' >/etc/systemd/system/kiwix-serve.service
[Unit]
Description=Kiwix ZIM Server
After=network.target

[Service]
Type=simple
# Use shell expansion to serve all .zim files in /data
ExecStart=/bin/sh -c 'exec /usr/local/bin/kiwix-serve --port 8080 /data/*.zim'
Restart=always
RestartSec=10
Nice=15

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/data

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q --now kiwix-serve

# Verify service started (allow a moment for startup)
sleep 2
if systemctl is-active --quiet kiwix-serve; then
  msg_ok "Created and Started Kiwix Service"
else
  msg_info "Service created but not running (may need .zim files)"
  msg_info "Check status with: systemctl status kiwix-serve"
fi

# =============================================================================
# CLEANUP & FINALIZATION
# =============================================================================

motd_ssh
customize
cleanup_lxc
