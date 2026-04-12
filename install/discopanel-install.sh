#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: DragoQC | Co-Author: nickheyer
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://discopanel.app/ | Github: https://github.com/nickheyer/discopanel

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "discopanel" "nickheyer/discopanel" "prebuild" "latest" "/opt/discopanel" "discopanel-linux-amd64.tar.gz"
setup_docker

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/discopanel.service
[Unit]
Description=DiscoPanel Service
After=network.target

[Service]
WorkingDirectory=/opt/discopanel
ExecStart=/opt/discopanel/discopanel-linux-amd64
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now discopanel
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
