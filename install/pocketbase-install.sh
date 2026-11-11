#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pocketbase.io/ | Repo: https://ganigeorgiev.com/pocketbase/pocketbase

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

RELEASE=$(curl_with_retry "https://ganigeorgiev.com/api/collections/releases/records?filter=channel.repository.name%3D%22pocketbase%22%20%26%26%20channel.name%3D%22default%22&sort=-semver&skipTotal=1&perPage=1" "-" | jq -r '.items[0].tag' | sed 's/^v//')
fetch_and_deploy_from_url "https://ganigeorgiev.com/meta/pocketbase/pocketbase/download/v${RELEASE}/pocketbase_${RELEASE}_linux_$(arch_resolve).zip" "/opt/pocketbase"
echo "${RELEASE}" >~/.pocketbase

msg_info "Configuring Pocketbase"
mkdir -p /opt/pocketbase/{pb_public,pb_migrations,pb_hooks}
msg_ok "Configured Pocketbase"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/pocketbase.service
[Unit]
Description = pocketbase

[Service]
Type           = simple
LimitNOFILE    = 4096
Restart        = always
RestartSec     = 5s
StandardOutput = append:/opt/pocketbase/errors.log
StandardError  = append:/opt/pocketbase/errors.log
ExecStart      = /opt/pocketbase/pocketbase serve --http=0.0.0.0:8080

[Install]
WantedBy = multi-user.target
EOF
systemctl enable -q --now pocketbase
msg_ok "Service created"

motd_ssh
customize
cleanup_lxc
