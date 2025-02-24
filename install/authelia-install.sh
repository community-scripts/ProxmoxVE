#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: thost96 (thost96)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.authelia.com/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc 
msg_ok "Installed Dependencies"

msg_info "Installing Authelia"
RELEASE=$(curl -s https://api.github.com/repos/authelia/authelia/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/authelia/authelia/releases/download/${RELEASE}/authelia_${RELEASE}_amd64.deb"
$STD dpkg -i "authelia_${RELEASE}_amd64.deb"
msg_ok "Install Authelia completed"

read -p "Enter your domain (ex. example.com): " DOMAIN

msg_info "Setting Authelia up"
touch /etc/authelia/emails.txt
JWT_SECRET=$(openssl rand  -hex 64)
SESSION_SECRET=$(openssl rand  -hex 64)
STORAGE_KEY=$(openssl rand  -hex 64)
cat <<EOF >/etc/authelia/users.yml
users:
  authelia:
    disabled: false
    displayname: "Authelia Admin"
    password: "\$argon2id\$v=19\$m=65536,t=3,p=4\$ZBopMzXrzhHXPEZxRDVT2w\$SxWm96DwhOsZyn34DLocwQEIb4kCDsk632PuiMdZnig"
    groups: []
EOF

cat <<EOF >/etc/authelia/configuration.yml
authentication_backend:
  file:
    path: /etc/authelia/users.yml
access_control:
  default_policy: one_factor
session:
  secret: "${SESSION_SECRET}"
  name: 'authelia_session'
  same_site: 'lax'
  inactivity: '5m'
  expiration: '1h'
  remember_me: '1M'
  cookies:
    - domain: "${DOMAIN}"
      authelia_url: "https://auth.${DOMAIN}"
storage:
  encryption_key: "${STORAGE_KEY}"
  local:
    path: /etc/authelia/db.sqlite
identity_validation:
  reset_password:
    jwt_secret: "${JWT_SECRET}"
    jwt_lifespan: '5 minutes'
    jwt_algorithm: 'HS256'
notifier:
  filesystem:
    filename: /etc/authelia/emails.txt
EOF
systemctl enable -q --now authelia
msg_ok "Authelia Setup completed"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "authelia_${RELEASE}_amd64.deb"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
