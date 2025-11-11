#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.openhab.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="21" setup_java

msg_info "Installing openHAB"
setup_deb822_repo \
  "openhab" \
  "https://openhab.jfrog.io/artifactory/api/gpg/key/public" \
  "https://openhab.jfrog.io/artifactory/openhab-linuxpkg" \
  "stable" \
  "main"
$STD apt install -y openhab
msg_ok "Installed openHAB"

msg_info "Initializing openHAB directories"
mkdir -p /var/lib/openhab/{tmp,etc,cache}
mkdir -p /etc/openhab
mkdir -p /var/log/openhab
chown -R openhab:openhab /var/lib/openhab /etc/openhab /var/log/openhab
msg_ok "Initialized openHAB directories"

msg_info "Starting Service"
systemctl daemon-reload
systemctl enable -q --now openhab
msg_ok "Started Service"

motd_ssh
customize
cleanup_lxc
