#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/fmd-foss/fmd-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gl_release "fmd-server" "fmd-foss/fmd-server" "prebuild" "latest" "/opt/fmd-server" "fmd-server-*.zip"
create_self_signed_cert

msg_info "Configuring fmd-server"
cd /opt/fmd-server
chmod +x fmd-server-*
cp config.example.yml config.yml
edit_yaml_config config.yml "WebDir" '"/opt/fmd-server/web/dist/"'
edit_yaml_config config.yml "DatabaseDir" '"/opt/fmd-server/db/"'
edit_yaml_config config.yml "ServerCrt" '"/etc/ssl/fmd-server/fmd-server.crt"'
edit_yaml_config config.yml "ServerKey" '"/etc/ssl/fmd-server/fmd-server.key"'
msg_ok "Configured fmd-server"

msg_info "Creating services"
cat <<EOF >/etc/systemd/system/fmd-server.service
[Unit]
Description=fmd-server Service
After=network.target

[Service]
WorkingDirectory=/opt/fmd-server
ExecStart=/opt/fmd-server/fmd-server-$(arch_resolve) serve
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now fmd-server
msg_ok "Created services"

motd_ssh
customize
cleanup_lxc
