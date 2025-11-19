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

msg_info "Installing Docker"
$STD sh <(curl -fsSL https://get.docker.com/)
msg_ok "Installed Docker"

msg_info "Detecting latest Kasm Workspaces release"
KASM_URL=$(curl -fsSL "https://www.kasm.com/downloads" | tr '\n' ' ' | grep -oE 'https://kasm-static-content[^"]*kasm_release_[0-9]+\.[0-9]+\.[0-9]+\.[a-z0-9]+\.tar\.gz' | head -n 1)
if [[ -z "$KASM_URL" ]]; then
  msg_error "Unable to detect latest Kasm release URL."
  exit 1
fi
KASM_VERSION=$(echo "$KASM_URL" | sed -E 's/.*kasm_release_([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
msg_ok "Detected Kasm Workspaces version $KASM_VERSION"

msg_warn "WARNING: This script will run an external installer from a third-party source (https://www.kasmweb.com/)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  install.sh inside tar.gz $KASM_URL"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

msg_info "Installing Kasm Workspaces"
curl -fsSL -o "/opt/kasm_release_${KASM_VERSION}.tar.gz" "$KASM_URL"
cd /opt
tar -xf "kasm_release_${KASM_VERSION}.tar.gz"
chmod +x /opt/kasm_release/install.sh
printf 'y\ny\ny\n4\n' | bash /opt/kasm_release/install.sh >~/kasm-install.output 2>&1
awk '
  /^Kasm UI Login Credentials$/ {capture=1}
  capture {print}
  /^Service Registration Token$/ {in_token=1}
  in_token && /^-+$/ {dash_count++}
  in_token && dash_count==2 {exit}
' ~/kasm-install.output >~/kasm.creds
rm -f /opt/kasm_release_${KASM_VERSION}.tar.gz
rm -f ~/kasm-install.output
msg_ok "Installed Kasm Workspaces"

motd_ssh
customize
cleanup_lxc
