#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y chromium
$STD apt-get install -y xvfb
msg_ok "Installed Dependencies"

if [[ "$CTTYPE" == "0" ]]; then
  msg_info "Setting Up Hardware Acceleration"
  $STD apt-get -y install \
    va-driver-all \
    ocl-icd-libopencl1 \
    intel-opencl-icd
  chgrp video /dev/dri
  chmod 755 /dev/dri
  chmod 660 /dev/dri/*
  $STD adduser $(id -u -n) video
  $STD adduser $(id -u -n) render
  msg_ok "Set Up Hardware Acceleration"
fi

msg_info "Installing Channels DVR Server (Patience)"
cd /opt
$STD bash <(curl -fsSL https://getchannels.com/dvr/setup.sh)
sed -i -e 's/^sgx:x:104:$/render:x:104:root/' -e 's/^render:x:106:root$/sgx:x:106:/' /etc/group
msg_ok "Installed Channels DVR Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
