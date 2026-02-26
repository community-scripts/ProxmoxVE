#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MorganCSIT
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://brew.sh | Github: https://github.com/Homebrew/brew

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y build-essential git curl file procps
msg_ok "Installed Dependencies"

msg_info "Detecting Non-Root User"
BREW_USER=$(awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }' /etc/passwd)
if [ -z "$BREW_USER" ]; then
  msg_error "No non-root user found (uid >= 1000). Create a user first."
  exit 1
fi
msg_ok "Detected User: $BREW_USER"

msg_info "Setting Up Homebrew Prefix"
export PATH="/usr/sbin:$PATH"
groupadd -f linuxbrew
mkdir -p /home/linuxbrew/.linuxbrew
chown -R "$BREW_USER":linuxbrew /home/linuxbrew
chmod 2775 /home/linuxbrew
chmod 2775 /home/linuxbrew/.linuxbrew
usermod -aG linuxbrew "$BREW_USER"
msg_ok "Set Up Homebrew Prefix"

msg_info "Installing Homebrew"
$STD su - "$BREW_USER" -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
msg_ok "Installed Homebrew"

msg_info "Configuring Shell Integration"
cat > /etc/profile.d/homebrew.sh << 'EOF'
#!/bin/bash
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
EOF
chmod +x /etc/profile.d/homebrew.sh

BREW_USER_HOME=$(eval echo "~$BREW_USER")
if ! grep -q 'linuxbrew' "$BREW_USER_HOME/.bashrc" 2>/dev/null; then
  cat >> "$BREW_USER_HOME/.bashrc" << 'EOF'

# Homebrew (Linuxbrew)
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
EOF
fi
msg_ok "Configured Shell Integration"

msg_info "Verifying Installation"
su - "$BREW_USER" -c 'brew --version'
msg_ok "Homebrew Verified"

motd_ssh
customize
cleanup_lxc
