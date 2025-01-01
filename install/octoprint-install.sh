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
$STD apt-get install -y git
$STD apt-get install -y libyaml-dev
$STD apt-get install -y build-essential
msg_ok "Installed Dependencies"

msg_info "Updating Python3"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv

$STD apt-get install -y python3-setuptools
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Updated Python3"

msg_info "Creating user octoprint"
useradd -m -s /bin/bash -p $(openssl passwd -1 octoprint) octoprint
usermod -aG sudo,tty,dialout octoprint
chown -R octoprint:octoprint /opt
echo "octoprint ALL=NOPASSWD: $(command -v systemctl) restart octoprint, $(command -v reboot), $(command -v poweroff)" > /etc/sudoers.d/octoprint
msg_ok "Created user octoprint"

msg_info "Installing OctoPrint"
$STD sudo -u octoprint bash << EOF
mkdir /opt/octoprint
cd /opt/octoprint
python3 -m venv .
source bin/activate
pip install --upgrade pip
pip install wheel
pip install octoprint
EOF
msg_ok "Installed OctoPrint"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/octoprint.service
[Unit]
Description=The snappy web interface for your 3D printer
After=network-online.target
Wants=network-online.target

[Service]
Environment="LC_ALL=C.UTF-8"
Environment="LANG=C.UTF-8"
Type=exec
User=octoprint
ExecStart=/opt/octoprint/bin/octoprint serve

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now octoprint.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
