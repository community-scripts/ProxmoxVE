#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.iventoy.com/en/index.html

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "iventoy" "ventoy/PXE" "prebuild" "latest" "/opt/iventoy" "iventoy-*-linux-$(arch_resolve x86_64-free arm64-trial).tar.gz"
mkdir -p /opt/iventoy/{data,iso}

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/iventoy.service
[Unit]
Description=iVentoy PXE Booter
Documentation=https://www.iventoy.com
Wants=network-online.target
After=network-online.target

[Service]
Type=forking
WorkingDirectory=/opt/iventoy
Environment=IVENTOY_API_ALL=1
Environment=IVENTOY_AUTO_RUN=1
Environment=LIBRARY_PATH=/opt/iventoy/lib/lin64
Environment=LD_LIBRARY_PATH=/opt/iventoy/lib/lin64
ExecStart=/bin/sh /opt/iventoy/iventoy.sh -R start
ExecStop=/bin/sh /opt/iventoy/iventoy.sh stop
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now iventoy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
