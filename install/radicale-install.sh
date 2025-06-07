#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
$STD apt-get install -y \
  apache2-utils
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv

msg_info "Setting up Radicale"
mkdir -p /opt/radicale/{users}
cd /opt/radicale
$STD uv venv /opt/radicale/.venv
$STD /opt/radicale/.venv/bin/python -m ensurepip --upgrade
$STD /opt/radicale/.venv/bin/python -m pip install --upgrade pip
$STD /opt/radicale/.venv/bin/python -m pip install --upgrade https://github.com/Kozea/Radicale/archive/master.tar.gz
RNDPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD htpasswd -c -b -5 /opt/radicale/users admin "$RNDPASS"
{
  echo "Radicale Credentials"
  echo "Admin User: admin"
  echo "Admin Password: $RNDPASS"
} >>~/radicale.creds
msg_ok "Done setting up Radicale"

msg_info "Setup Service"
cat <<EOF >/opt/radicale/start.sh
#!/usr/bin/env bash
uv run -m radicale --storage-filesystem-folder=/var/lib/radicale/collections --hosts 0.0.0.0:5232 --auth-type htpasswd --auth-htpasswd-filename /opt/radicale/users --auth-htpasswd-encryption sha512
EOF

chmod +x /opt/radicale/start.sh

cat <<EOF >/etc/systemd/system/radicale.service
[Unit]
Description=A simple CalDAV (calendar) and CardDAV (contact) server
After=network.target
Requires=network.target

[Service]
ExecStart=/opt/radicale/start.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now radicale
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
