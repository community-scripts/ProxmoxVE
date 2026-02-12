#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://radicale.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y apache2-utils
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "Radicale" "Kozea/Radicale" "tarball" "latest" "/opt/radicale"

msg_info "Setting up Radicale"
cd /opt/radicale
RNDPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD htpasswd -c -b -5 /opt/radicale/users admin "$RNDPASS"
{
  echo "Radicale Credentials"
  echo "Admin User: admin"
  echo "Admin Password: $RNDPASS"
} >>~/radicale.creds
msg_ok "Done setting up Radicale"

msg_info "Setup Service"
cat <<EOF >/etc/systemd/system/radicale.service
[Unit]
Description=A simple CalDAV (calendar) and CardDAV (contact) server
After=network.target
Requires=network.target

[Service]
WorkingDirectory=/opt/radicale
ExecStart=/usr/local/bin/uv run -m radicale --storage-filesystem-folder=/var/lib/radicale/collections --hosts 0.0.0.0:5232 --auth-type htpasswd --auth-htpasswd-filename /opt/radicale/users --auth-htpasswd-encryption sha512
Restart=on-failure
# User=radicale
# Deny other users access to the calendar data
# UMask=0027

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now radicale
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
