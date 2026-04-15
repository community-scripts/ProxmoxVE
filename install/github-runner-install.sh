#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.github.com/en/actions/hosting-your-own-runners

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  gh
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

msg_info "Creating runner user (no sudo)"
useradd -m -s /bin/bash runner
msg_ok "Runner user ready"

fetch_and_deploy_gh_release "actions-runner" "actions/runner" "prebuild" "latest" "/opt/actions-runner" "actions-runner-linux-x64-*.tar.gz"

msg_info "Setting ownership for runner user"
chown -R runner:runner /opt/actions-runner
msg_ok "Ownership set"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/actions-runner.service
[Unit]
Description=GitHub Actions self-hosted runner
Documentation=https://docs.github.com/en/actions/hosting-your-own-runners
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=runner
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q actions-runner
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
