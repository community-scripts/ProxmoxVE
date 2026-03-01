#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.emqx.com/en

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y ca-certificates
msg_ok "Installed dependencies"

msg_info "Fetching latest EMQX Enterprise version"
LATEST_VERSION=$(curl -fsSL https://www.emqx.com/en/downloads/enterprise | grep -oP '/en/downloads/enterprise/v\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n1)
if [[ -z "$LATEST_VERSION" ]]; then
  msg_error "Failed to determine latest EMQX version"
  exit 1
fi
msg_ok "Latest version: v$LATEST_VERSION"

DOWNLOAD_URL="https://www.emqx.com/en/downloads/enterprise/v$LATEST_VERSION/emqx-enterprise-${LATEST_VERSION}-debian12-amd64.deb"
DEB_FILE="/tmp/emqx-enterprise-${LATEST_VERSION}-debian12-amd64.deb"

msg_info "Downloading EMQX v$LATEST_VERSION"
$STD curl -fsSL -o "$DEB_FILE" "$DOWNLOAD_URL"
msg_ok "Downloaded EMQX"

msg_info "Installing EMQX"
$STD apt install -y "$DEB_FILE"
rm -f "$DEB_FILE"
echo "$LATEST_VERSION" >~/.emqx
msg_ok "Installed EMQX"

read -r -p "${TAB3}Would you like to disable the EMQX MQ feature? (reduces disk/CPU usage) <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Disabling EMQX MQ feature"
  mkdir -p /etc/emqx
  if ! grep -q "^mq.enable" /etc/emqx/emqx.conf 2>/dev/null; then
    echo "mq.enable = false" >>/etc/emqx/emqx.conf
  else
    sed -i 's/^mq.enable.*/mq.enable = false/' /etc/emqx/emqx.conf
  fi
  msg_ok "Disabled EMQX MQ feature"
fi

msg_info "Starting EMQX service"
$STD systemctl enable -q --now emqx
msg_ok "Enabled EMQX service"

motd_ssh
customize
cleanup_lxc

