#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ezbookkeeping.mayswind.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "ezbookkeeping" "mayswind/ezbookkeeping" "prebuild" "latest" "/opt/ezbookkeeping" "ezbookkeeping-*-linux-$(get_arch_value).tar.gz"
create_self_signed_cert

msg_info "Configuring ezBookkeeping"
SECRET_KEY=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c50)
sed -i "s/enable_gzip = false/enable_gzip = true/" /opt/ezbookkeeping/conf/ezbookkeeping.ini
sed -i "s/protocol = http/protocol = https/" /opt/ezbookkeeping/conf/ezbookkeeping.ini
sed -i "s/http_port = 8080/http_port = 443/" /opt/ezbookkeeping/conf/ezbookkeeping.ini
sed -i "s/cert_file =/cert_file = \/etc\/ssl\/ezbookkeeping\/ezbookkeeping.crt/" /opt/ezbookkeeping/conf/ezbookkeeping.ini
sed -i "s/cert_key_file =/cert_key_file = \/etc\/ssl\/ezbookkeeping\/ezbookkeeping.key/" /opt/ezbookkeeping/conf/ezbookkeeping.ini
sed -i "s/domain = localhost/domain = ${LOCAL_IP}/" /opt/ezbookkeeping/conf/ezbookkeeping.ini
sed -i "s/secret_key =/secret_key = ${SECRET_KEY}/" /opt/ezbookkeeping/conf/ezbookkeeping.ini
msg_ok "Configured ezBookkeeping"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/ezbookkeeping.service
[Unit]
Description=ezBookkeeping Service
After=network.target

[Service]
WorkingDirectory=/opt/ezbookkeeping
ExecStart=/opt/ezbookkeeping/ezbookkeeping server run
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ezbookkeeping
msg_ok "Created service"

motd_ssh
customize
cleanup_lxc
