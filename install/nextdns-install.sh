#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nick Berardi (nberardi)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nextdns.io | https://github.com/nextdns/nextdns

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb822_repo \
  "nextdns" \
  "https://repo.nextdns.io/nextdns.gpg" \
  "https://repo.nextdns.io/deb" \
  "stable" \
  "main"

msg_info "Installing NextDNS"
$STD apt install -y nextdns
msg_ok "Installed NextDNS"

if [[ -z "${var_nextdns_profile:-}" ]]; then
  echo -e "${INFO}${YW}Get your profile ID from: https://my.nextdns.io${CL}"
  read -r -p "${TAB3}NextDNS Profile ID: " var_nextdns_profile || true
fi
var_nextdns_profile="${var_nextdns_profile//[[:space:]]/}"
if [[ -z "${var_nextdns_profile}" ]]; then
  msg_error "NextDNS Profile ID is required (set var_nextdns_profile or enter it when prompted)"
  exit 64
fi

msg_info "Configuring NextDNS"
nextdns install \
  -profile "${var_nextdns_profile}" \
  -report-client-info \
  -setup-router
mkdir -p /etc/systemd/system/nextdns.service.d
cat <<EOF >/etc/systemd/system/nextdns.service.d/network-online.conf
[Unit]
Wants=network-online.target
After=network-online.target
EOF
systemctl daemon-reload
msg_ok "Configured NextDNS (profile ${var_nextdns_profile})"

motd_ssh
customize
cleanup_lxc
