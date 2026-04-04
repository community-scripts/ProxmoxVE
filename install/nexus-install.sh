#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Footgod-alt
# License: MIT | https://github.com/footgod-alt/ProxmoxVE-Nexus/raw/main/LICENSE
# Source: https://github.com/sonatype/nexus-public

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
LOG_FILE="/opt/sonatype-work/nexus3/log/nexus.log"
TARGET="Started Sonatype Nexus"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# =================
# DEPENDENCIES
# =================

msg_info "Installing Dependencies"
$STD apt update && apt upgrade -y
$STD apt install -y \
  wget \
  tar \
  apt-transport-https \
  gpg
msg_ok "Installed Dependencies"

# ===============
# SETUP JAVA
# ===============
   JAVA_VERSION="17" setup_java

# ==================================
# DOWNLOAD & DEPLOY APPLICATION
# ==================================
NEXUS_VERSION=$(curl -s "https://api.github.com/repos/sonatype/nexus-public/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"release-?([^"]+)".*/\1/')
# Examples:
#   fetch_and_deploy_gh_release "myapp" "YourUsername/myapp" "tarball" "latest" "/opt/myapp"
#   fetch_and_deploy_gh_release "myapp" "YourUsername/myapp" "binary" "latest" "/tmp"
#   fetch_and_deploy_gh_release "myapp" "YourUsername/myapp" "prebuild" "latest" "/opt/myapp" "myapp-*.tar.gz"
msg_info "Setting up Nexus ${NEXUS_VERSION}"
mkdir -p /opt/extract /opt/nexus /opt/sonatype-work
wget https://cdn.download.sonatype.com/repository/downloads-prod-group/3/nexus-"${NEXUS_VERSION}"-linux-x86_64.tar.gz -O /opt/extract/nexus.tar.gz
tar -xvzf /opt/extract/nexus.tar.gz -C /opt/extract
mv "/opt/extract/nexus-${NEXUS_VERSION}/*" /opt/nexus
mv /opt/extract/sonatype-work /opt/sonatype-work
msg_ok "Set up Nexus ${NEXUS_VERSION}"

# ==============================
# Run Post-Install Commands
# ==============================

msg_info "Setting up nexus user"
useradd -M -d /opt/nexus -s /bin/bash nexus || true
chown -R nexus:nexus /opt/nexus /opt/sonatype-work
/bin/echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc
msg_ok "Set up nexus user"

msg_info "Setting up systemd service for Nexus"
cat << EOF > /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nexus
systemctl start nexus
msg_ok "Set up systemd service for Nexus"


msg_info "Waiting for Nexus to start..."
while ! grep -q "$TARGET" "$LOG_FILE"; do
    sleep 2  # wait 2 seconds before checking again
done
msg_ok "Nexus started successfully!"

motd_ssh
customize
cleanup_lxc
