#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://unpackerr.zip/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "unpackerr" "Unpackerr/unpackerr" "binary" "latest" "/opt/unpackerr" "unpackerr_*_$(arch_resolve).deb"

msg_info "Configuring Unpackerr"
mkdir -p /etc/unpackerr
cat <<EOF >/etc/unpackerr/unpackerr.conf
debug = false
quiet = false
activity = false
interval = "2m"
parallel = 1
file_mode = "0644"
dir_mode = "0755"

[webserver]
metrics = false
listen_addr = "0.0.0.0:5656"

[folders]
interval = "0s"
EOF
chmod 640 /etc/unpackerr/unpackerr.conf
msg_ok "Configured Unpackerr"

msg_info "Creating Service"
systemctl enable -q --now unpackerr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
