#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/coredns/coredns

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "coredns" "coredns/coredns" "prebuild" "latest" "/usr/local/bin" \
  "coredns_*_linux_$(dpkg --print-architecture).tgz"
chmod +x /usr/local/bin/coredns

msg_info "Configuring CoreDNS"
mkdir -p /etc/coredns
cat <<EOF >/etc/coredns/Corefile
. {
    forward . 1.1.1.1 1.0.0.1
    cache 30
    log
    errors
    health :8080
    ready :8181
}
EOF
msg_ok "Configured CoreDNS"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/coredns.service
[Unit]
Description=CoreDNS DNS Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/coredns -conf /etc/coredns/Corefile
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now coredns
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
