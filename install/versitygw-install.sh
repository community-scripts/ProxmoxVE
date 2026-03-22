#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/versity/versitygw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "versitygw" "versity/versitygw" "binary"

WEBUI_CONF=""
read -rp "Would you like to enable the VersityGW WebGUI (Beta)? (y/N): " webui_prompt
if [[ "${webui_prompt,,}" =~ ^(y|yes)$ ]]; then
  WEBUI_CONF="\nVGW_WEBUI_PORT=:7071\nVGW_WEBUI_NO_TLS=true"
  msg_ok "WebGUI will be enabled on port 7071"
fi

msg_info "Configuring VersityGW"
mkdir -p /opt/versitygw-data
ACCESS_KEY=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-20)
SECRET_KEY=$(openssl rand -base64 36 | tr -dc 'a-zA-Z0-9' | cut -c1-40)

cat <<EOF >/etc/versitygw.d/gateway.conf
VGW_BACKEND=posix
VGW_BACKEND_ARG=/opt/versitygw-data
VGW_PORT=:7070
ROOT_ACCESS_KEY_ID=${ACCESS_KEY}
ROOT_SECRET_ACCESS_KEY=${SECRET_KEY}
EOF

if [[ -n "$WEBUI_CONF" ]]; then
  echo -e "$WEBUI_CONF" >>/etc/versitygw.d/gateway.conf
fi
msg_ok "Configured VersityGW"

msg_info "Enabling Service"
systemctl enable -q --now versitygw@gateway
msg_ok "Enabled Service"

motd_ssh
customize
cleanup_lxc
