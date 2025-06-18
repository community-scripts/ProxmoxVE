#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/element-hq/synapse

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  lsb-release \
  apt-transport-https \
  debconf-utils
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

read -p "${TAB3}Please enter the name for your server: " servername

msg_info "Installing Element Synapse"
curl -fsSL "https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg" -o "/usr/share/keyrings/matrix-org-archive-keyring.gpg"
echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main" >/etc/apt/sources.list.d/matrix-org.list
$STD apt-get update
echo "matrix-synapse-py3 matrix-synapse/server-name string $servername" | debconf-set-selections
echo "matrix-synapse-py3 matrix-synapse/report-stats boolean false" | debconf-set-selections
$STD apt-get install matrix-synapse-py3 -y
systemctl stop matrix-synapse
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/matrix-synapse/homeserver.yaml
sed -i 's/'\''::1'\'', //g' /etc/matrix-synapse/homeserver.yaml
SECRET=$(openssl rand -hex 32)
ADMIN_PASS="$(openssl rand -base64 18 | cut -c1-13)"
echo "enable_registration_without_verification: true" >>/etc/matrix-synapse/homeserver.yaml
echo "registration_shared_secret: ${SECRET}" >>/etc/matrix-synapse/homeserver.yaml
systemctl enable -q --now matrix-synapse
$STD register_new_matrix_user -a --user admin --password "$ADMIN_PASS" --config /etc/matrix-synapse/homeserver.yaml
{
  echo "Matrix-Credentials"
  echo "Admin username: admin"
  echo "Admin password: $ADMIN_PASS"
} >>~/matrix.creds
systemctl stop matrix-synapse
sed -i '34d' /etc/matrix-synapse/homeserver.yaml
systemctl start matrix-synapse
temp_file=$(mktemp)
mkdir -p /opt/synapse-admin
RELEASE=$(curl -fsSL https://api.github.com/repos/etkecc/synapse-admin/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/etkecc/synapse-admin/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
tar xzf "$temp_file" -C /opt/synapse-admin --strip-components=1
cd /opt/synapse-admin
$STD yarn global add serve
$STD yarn install --ignore-engines
$STD yarn build
mv ./dist ../ &&
  rm -rf * &&
  mv ../dist ./
msg_ok "Installed Element Synapse"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/synapse-admin.service
[Unit]
Description=Synapse-Admin Service
After=network.target
Requires=matrix-synapse.service

[Service]
Type=simple
WorkingDirectory=/opt/synapse-admin
ExecStart=/usr/local/bin/serve -s dist -l 5173
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now synapse-admin
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
