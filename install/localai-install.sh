#!/usr/bin/env bash
# Source: https://github.com/mudler/LocalAI

APP="localai"
GH_REPO="mudler/LocalAI"
BINARY="local-ai"

# Header
header_info "$APP"

# Setup
BASE_DIR="/opt/localai"
MODELS_DIR="$BASE_DIR/models"

# Install dependencies
msg_info "Installing dependencies"
$STD apt-get update
$STD apt-get install -y curl
msg_ok "Installed dependencies"

# Download and install LocalAI binary
msg_info "Downloading $APP binary"
fetch_and_deploy_gh_release "$GH_REPO" "prebuild" "$BINARY"
msg_ok "Downloaded $APP binary"

# Create directories
msg_info "Setting up directories"
mkdir -p "$MODELS_DIR"
msg_ok "Created directories"

# Create systemd service
msg_info "Creating systemd service"
cat <<EOF >/etc/systemd/system/localai.service
[Unit]
Description=LocalAI - OpenAI-compatible local inference server
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/local-ai
Restart=on-failure
RestartSec=5
Environment=LOCALAI_MODELS_PATH=$MODELS_DIR

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
msg_ok "Created systemd service"

# Enable and start service
msg_info "Starting $APP service"
systemctl enable --now localai
msg_ok "Started $APP service"

# Footer
motd_ssh
customize
cleanup_lxc
