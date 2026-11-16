#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/unslothai/unsloth

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  libgomp1 \
  git
msg_ok "Installed Dependencies"

UV_PYTHON="3.12" setup_uv
NODE_VERSION="22" setup_nodejs

setup_hwaccel

msg_info "Setting up Unsloth Studio (Patience)"
mkdir -p /opt/unsloth_data
curl -fsSL https://unsloth.ai/install.sh -o /tmp/unsloth-install.sh
export UNSLOTH_STUDIO_HOME=/opt/unsloth
export UNSLOTH_SKIP_AUTOSTART=1
export UNSLOTH_PYTHON=3.12
$STD sh /tmp/unsloth-install.sh
unset UNSLOTH_SKIP_AUTOSTART UNSLOTH_PYTHON
rm -f /tmp/unsloth-install.sh
[[ -x /opt/unsloth/unsloth_studio/bin/unsloth ]] || {
  msg_error "Unsloth Studio was not installed to /opt/unsloth/unsloth_studio"
  exit 1
}
msg_ok "Set up Unsloth Studio"

msg_info "Configuring Unsloth Studio"
cat <<EOF >/opt/unsloth.env
UNSLOTH_STUDIO_HOME=/opt/unsloth
HF_HOME=/opt/unsloth_data/huggingface
EOF
chmod 600 /opt/unsloth.env

UNSLOTH_PASSWORD=$(UNSLOTH_STUDIO_HOME=/opt/unsloth \
  /opt/unsloth/unsloth_studio/bin/unsloth studio reset-password |
  sed -n "s/^New password for 'unsloth': //p")
[[ -n "$UNSLOTH_PASSWORD" ]] || {
  msg_error "Could not set the initial Unsloth admin password"
  exit 1
}

cat <<EOF >~/unsloth.creds
Unsloth Studio
Username: unsloth
Password: ${UNSLOTH_PASSWORD}
EOF
chmod 600 ~/unsloth.creds
msg_ok "Configured Unsloth Studio"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/unsloth.service
[Unit]
Description=Unsloth Studio
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/unsloth_data
EnvironmentFile=/opt/unsloth.env
ExecStart=/opt/unsloth/unsloth_studio/bin/unsloth studio -H 0.0.0.0 -p 8888
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now unsloth
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
