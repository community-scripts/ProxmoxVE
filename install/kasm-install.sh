#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kasmweb.com/docs/latest/index.html

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_docker

msg_info "Detecting latest Kasm Workspaces release"
KASM_URL=$(curl -s https://kasm.com/downloads \
  | grep -oP 'https://kasm-static-content\.s3\.amazonaws\.com/kasm_release_\d+\.\d+\.\d+-latest\.tar\.gz' \
  | head -1)
KASM_VERSION=$(echo "$KASM_URL" | grep -oP '\d+\.\d+\.\d+(?=-latest)')

# Fallback to predefined version if online lookup failed.
if [[ -z "$KASM_VERSION" ]] || [[ -z "$KASM_URL" ]]; then
  msg_warn "Unable to fetch latest Kasm release online, falling back to v${var_kasm_version}"
fi

KASM_VERSION="${KASM_VERSION:-$var_kasm_version}"
KASM_URL="${KASM_URL:-https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_VERSION}-latest.tar.gz}"

if [[ -z "$KASM_VERSION" ]] || [[ -z "$KASM_URL" ]]; then
  msg_error "Unable to detect latest Kasm release URL."
  exit 250
fi
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
curl_download "/opt/kasm_release_${KASM_VERSION}.tar.gz" "$KASM_URL"
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
