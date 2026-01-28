#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

MAX_ATTEMPTS=3
attempt=0
while true; do
  attempt=$((attempt + 1))
  read -rp "${TAB3}Enter your domain or IP (ex. example.com or 192.168.1.100): " DOMAIN
  if [[ -z "$DOMAIN" ]]; then
    if ((attempt >= MAX_ATTEMPTS)); then
      DOMAIN="${LOCAL_IP:-localhost}"
      msg_warn "Using fallback: $DOMAIN"
      break
    fi
    msg_warn "Domain cannot be empty! (Attempt $attempt/$MAX_ATTEMPTS)"
  elif [[ "$DOMAIN" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    valid_ip=true
    IFS='.' read -ra octets <<< "$DOMAIN"
    for octet in "${octets[@]}"; do
      if ((octet > 255)); then
        valid_ip=false
        break
      fi
    done
    if $valid_ip; then
      break
    else
      msg_warn "Invalid IP address!"
    fi
  elif [[ "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
    break
  else
    msg_warn "Invalid domain format!"
  fi
done
msg_info "Setting Authelia up"
touch /etc/authelia/emails.txt
JWT_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 64)
STORAGE_KEY=$(openssl rand -hex 64)

if [[ "$DOMAIN" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  AUTHELIA_URL="https://${DOMAIN}:9091"
else
  AUTHELIA_URL="https://auth.${DOMAIN}"
fi
echo "$AUTHELIA_URL" > /etc/authelia/.authelia_url

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
      authelia_url: "${AUTHELIA_URL}"
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
cleanup_lxc
