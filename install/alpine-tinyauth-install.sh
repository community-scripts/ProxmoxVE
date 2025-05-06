#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/steveiliop56/tinyauth

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add --no-cache \
  npm \
  curl \
  go
msg_ok "Installed Dependencies"

msg_info "Installing tinyauth"
temp_file=$(mktemp)
$STD npm install -g bun
mkdir -p /opt/tinyauth
RELEASE=$(curl -s https://api.github.com/repos/steveiliop56/tinyauth/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/steveiliop56/tinyauth/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
tar -xzf "$temp_file" -C /opt/tinyauth --strip-components=1
cd /opt/tinyauth/frontend
$STD bun install
$STD bun run build
mv dist /opt/tinyauth/internal/assets/
cd /opt/tinyauth
$STD go mod download
CGO_ENABLED=0 go build -ldflags "-s -w"
{
  echo "tinyauth Credentials"
  echo "Username: admin@example.com"
  echo "Password: admin"
} >>~/tinyauth.creds
echo "${RELEASE}" >/opt/tinyauth_version.txt
msg_ok "Installed tinyauth"

msg_info "Enabling tinyauth Service"
SECRET=$(head -c 16 /dev/urandom | xxd -p -c 16 | tr -d '\n')
{
  echo "SECRET=${SECRET}"
  echo "USERS=admin@example.com:\$2a\$10\$CrTK.W7WXSClo3ZY1yJUFupg5UdV8WNcynEhZhJFNjhGQB.Ga0ZDm"
  echo "APP_URL=http://localhost:3000"
} >>/opt/tinyauth/.env

cat <<EOF >/etc/init.d/tinyauth
#!/sbin/openrc-run
description="tinyauth Service"

command="/opt/tinyauth/tinyauth"
directory="/opt/tinyauth"
command_user="root"
command_background="true"
pidfile="/var/run/tinyauth.pid"

start_pre() {
    if [ -f "/opt/tinyauth/.env" ]; then
        export \$(grep -v '^#' /opt/tinyauth/.env | xargs)
    fi
}

depend() {
    use net
}
EOF

chmod +x /etc/init.d/tinyauth
$STD rc-update add tinyauth default
msg_ok "Enabled tinyauth Service"

msg_info "Starting tinyauth"
$STD service tinyauth start
msg_ok "Started tinyauth"

motd_ssh
customize
