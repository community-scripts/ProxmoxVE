#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Arubinu
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fosrl/newt

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "newt" "fosrl/newt" "singlefile" "latest" "/opt/newt" "newt_linux_$(arch_resolve)"
ln -sf /opt/newt/newt /usr/local/bin/newt

NEWT_ID="${NEWT_ID:-${var_newt_id:-}}"
[[ -n "$NEWT_ID" ]] || read -rp "Newt ID (from your Pangolin dashboard): " NEWT_ID || true
NEWT_SECRET="${NEWT_SECRET:-${var_newt_secret:-}}"
if [[ -z "$NEWT_SECRET" ]]; then
  read -rsp "Newt Secret: " NEWT_SECRET || true
  echo
fi
PANGOLIN_ENDPOINT="${PANGOLIN_ENDPOINT:-${var_newt_endpoint:-}}"
[[ -n "$PANGOLIN_ENDPOINT" ]] || read -rp "Pangolin endpoint (e.g. https://pangolin.example.com): " PANGOLIN_ENDPOINT || true

if [[ -z "$NEWT_ID" || -z "$NEWT_SECRET" || -z "$PANGOLIN_ENDPOINT" ]]; then
  msg_error "Newt ID, Secret and Endpoint are all required. Aborting."
  exit 1
fi

msg_info "Configuring Newt"
mkdir -p /etc/newt
cat <<EOF >/etc/newt/newt.env
NEWT_ID=${NEWT_ID}
NEWT_SECRET=${NEWT_SECRET}
PANGOLIN_ENDPOINT=${PANGOLIN_ENDPOINT}
EOF
chmod 600 /etc/newt/newt.env
msg_ok "Configured Newt"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/newt.service
[Unit]
Description=Newt (Pangolin tunnel client)
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/newt/newt.env
ExecStart=/usr/local/bin/newt
Restart=always
RestartSec=2
UMask=0077
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now newt
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
