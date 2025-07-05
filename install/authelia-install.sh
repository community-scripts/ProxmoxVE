#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: thost96 (thost96)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.authelia.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "authelia" "authelia/authelia" "binary"

read -rp "${TAB3}Enter your domain (ex. example.com): " DOMAIN

msg_info "Setting Authelia up"
touch /etc/authelia/emails.txt
JWT_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 64)
STORAGE_KEY=$(openssl rand -hex 64)
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
touch /etc/authelia/emails.txt
chown -R authelia:authelia /etc/authelia
systemctl enable -q --now authelia
msg_ok "Authelia Setup completed"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
