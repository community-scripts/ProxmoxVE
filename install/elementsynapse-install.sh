#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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
$STD apt install -y \
  apt-transport-https \
  debconf-utils
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

read -p "${TAB3}Please enter the name for your server: " servername

msg_info "Installing Element Synapse"
setup_deb822_repo "matrix-org" \
  "https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg" \
  "https://packages.matrix.org/debian/" \
  "$(get_os_info codename)" \
  "main"
echo "matrix-synapse-py3 matrix-synapse/server-name string $servername" | debconf-set-selections
echo "matrix-synapse-py3 matrix-synapse/report-stats boolean false" | debconf-set-selections
$STD apt install matrix-synapse-py3 -y
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
msg_ok "Installed Element Synapse"

fetch_and_deploy_gh_release "synapse-admin" "etkecc/synapse-admin" "tarball"

msg_info "Installing Synapse-Admin"
cd /opt/synapse-admin
$STD yarn global add serve
$STD yarn install --ignore-engines
$STD yarn build
mv ./dist ../ &&
  rm -rf * &&
  mv ../dist ./
msg_ok "Installed Synapse-Admin"

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
cleanup_lxc
