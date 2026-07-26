#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cooklang/cookcli

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "cook" "cooklang/cookcli" "prebuild" "latest" "/opt/cookcli" "cook-$(arch_resolve "x86_64-unknown-linux-gnu" "aarch64-unknown-linux-musl").tar.gz"

msg_info "Configuring CookCLI"
chmod +x /opt/cookcli/cook
mkdir -p /opt/cookcli/recipes
cd /opt/cookcli/recipes
$STD /opt/cookcli/cook seed
msg_ok "Configured CookCLI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cookcli.service
[Unit]
Description=CookCLI Recipe Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cookcli/recipes
ExecStart=/opt/cookcli/cook server --host 0.0.0.0 --port 9080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cookcli
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
