#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ), twingate-andrewb
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.twingate.com/docs/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

install -d -m 0700 /etc/twingate
access_token=""
refresh_token=""
network=""
while [[ -z "$access_token" ]]; do
  read -rp "${TAB3}Please enter your access token: " access_token
done
while [[ -z "$refresh_token" ]]; do
  read -rp "${TAB3}Please enter your refresh token: " refresh_token
done
while [[ -z "$network" ]]; do
  read -rp "${TAB3}Please enter your network name: " network
done

msg_info "Setup Twingate Repository"
curl -fsSL "https://packages.twingate.com/apt/gpg.key" | gpg --dearmor -o /usr/share/keyrings/twingate-connector-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/twingate-connector-keyring.gpg] https://packages.twingate.com/apt/ /" > /etc/apt/sources.list.d/twingate.list
$STD apt-get update
msg_ok "Setup Twingate Repository"

msg_info "Setup Twingate Connector"
$STD apt-get install -y twingate-connector
msg_ok "Setup Twingate Connector"

msg_info "Configure Twingate-Connector"
{
  echo "TWINGATE_NETWORK=${network}"
  echo "TWINGATE_ACCESS_TOKEN=${access_token}"
  echo "TWINGATE_REFRESH_TOKEN=${refresh_token}"
  echo "TWINGATE_LABEL_HOSTNAME=$(hostname)"
  echo "TWINGATE_LABEL_DEPLOYED_BY=proxmox"
} > /etc/twingate/connector.conf
chmod 600 /etc/twingate/connector.conf
msg_ok "Configured Twingate-Connector"

msg_info "Starting Service"
systemctl enable -q --now twingate-connector
msg_ok "Service started"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
