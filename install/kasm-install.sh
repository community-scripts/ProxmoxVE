#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Omar Minaya
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kasmweb.com/docs/latest/index.html

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Kasm Workspaces"
KASM_VERSION=$(curl -fsSL 'https://www.kasmweb.com/downloads' | grep -o 'https://kasm-static-content.s3.amazonaws.com/kasm_release_[^"]*\.tar\.gz' | head -n 1 | sed -E 's/.*release_(.*)\.tar\.gz/\1/')
curl -fsSL -o "/opt/kasm_release_${KASM_VERSION}.tar.gz" "https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_VERSION}.tar.gz"
cd /opt
tar -xf "kasm_release_${KASM_VERSION}.tar.gz"
chmod +x /opt/kasm_release/install.sh
printf 'y\ny\ny\n4\n' | bash /opt/kasm_release/install.sh > ~/kasm-install.output 2>&1
awk '
  /^Kasm UI Login Credentials$/ {capture=1}
  capture {print}
  /^Service Registration Token$/ {in_token=1}
  in_token && /^-+$/ {dash_count++}
  in_token && dash_count==2 {exit}
' ~/kasm-install.output > ~/kasm.creds
msg_ok "Installed Kasm Workspaces"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /opt/kasm_release_${KASM_VERSION}.tar.gz
rm -f ~/kasm-install.output
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
