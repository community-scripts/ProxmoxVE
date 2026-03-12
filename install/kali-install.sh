#!/usr/bin/env bash

# Author: Heretek-AI
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://images.linuxcontainers.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Kali Linux Essential Tools"

# Pre-configure debconf to avoid interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Pre-answer wireshark-common prompt about non-root packet capture
echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections 2>/dev/null || true

# Install essential Kali security tools (minimal footprint)
$STD apt-get install -y \
  nmap \
  curl \
  wget \
  git \
  net-tools \
  iputils-ping \
  dnsutils \
  whois \
  netcat-openbsd \
  tcpdump \
  john \
  hashcat \
  hydra

# Install optional larger packages (may fail in minimal environment)
$STD apt-get install -y wireshark-common 2>/dev/null || true
$STD apt-get install -y metasploit-framework 2>/dev/null || true
$STD apt-get install -y kali-tools-top10 2>/dev/null || true

msg_ok "Installed Kali Linux Essential Tools"

msg_info "Configuring Kali Environment"

# Ensure Kali repositories are configured
if [[ ! -f /etc/apt/sources.list.d/kali.list ]]; then
  cat <<EOF > /etc/apt/sources.list.d/kali.list
# Kali Linux Repository
deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF
fi

# Update package lists with Kali repos
$STD apt-get update 2>/dev/null || true

msg_ok "Configured Kali Environment"

motd_ssh
customize
cleanup_lxc

# Get container IP for display
LOCAL_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
echo " Kali Linux LXC Installation Complete!"
echo "=========================================="
echo ""
echo "Access the container:"
echo "  pct enter ${CTID}"
echo "  ssh root@${LOCAL_IP}"
echo ""
echo "Install additional Kali tools:"
echo "  apt install kali-tools-<category>"
echo ""
echo "Available tool categories:"
echo "  kali-tools-top10              - Top 10 tools"
echo "  kali-tools-information-gathering"
echo "  kali-tools-vulnerability"
echo "  kali-tools-web"
echo "  kali-tools-password"
echo "  kali-tools-wireless"
echo "  kali-tools-exploitation"
echo "  kali-tools-forensic"
echo "  kali-tools-reporting"
echo "  kali-tools-social-engineering"
echo ""
echo "Full installation:"
echo "  apt install kali-linux-everything"
echo "=========================================="
