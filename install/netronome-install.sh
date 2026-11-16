#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/autobrr/netronome

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  iperf3 \
  iputils-ping \
  mtr-tiny \
  traceroute
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "librespeed-cli" "librespeed/speedtest-cli" "prebuild" "latest" "/opt/librespeed-cli" "librespeed-cli_*_linux_$(arch_resolve).tar.gz"
ln -sf /opt/librespeed-cli/librespeed-cli /usr/local/bin/librespeed-cli
fetch_and_deploy_gh_release "netronome" "autobrr/netronome" "binary" "latest" "" "netronome_*_linux_$(arch_resolve).deb" "v"

msg_info "Configuring Netronome"
mkdir -p /opt/netronome_data /root/.config
$STD netronome generate-config --config /opt/netronome_data/config.toml
sed -i 's/^host = "127.0.0.1"$/host = "0.0.0.0"/' /opt/netronome_data/config.toml
chmod 600 /opt/netronome_data/config.toml
ln -s /opt/netronome_data /root/.config/netronome
msg_ok "Configured Netronome"

msg_info "Creating Netronome Service"
cat <<EOF >/etc/systemd/system/netronome.service
[Unit]
Description=Netronome
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/netronome_data
ExecStart=/usr/bin/netronome serve --config /opt/netronome_data/config.toml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now netronome
msg_ok "Created Netronome Service"

motd_ssh
customize
cleanup_lxc
