#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021) | Co-Author: Stavros (steveiliop56)
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
$STD apk add --no-cache openssl apache2-utils
msg_ok "Installed Dependencies"

msg_info "Installing Tinyauth"
mkdir -p /opt/tinyauth
RELEASE=$(curl -s https://api.github.com/repos/steveiliop56/tinyauth/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/steveiliop56/tinyauth/releases/download/v${RELEASE}/tinyauth-amd64" -o /opt/tinyauth/tinyauth
chmod +x /opt/tinyauth/tinyauth
PASS=$(openssl rand -base64 8 | tr -dc 'a-zA-Z0-9' | head -c 8)
USER=$(htpasswd -Bbn "tinyauth" "${PASS}")

cat <<EOF >/opt/tinyauth/credentials.txt
Tinyauth Credentials
Username: tinyauth
Password: ${PASS}
EOF
echo "${RELEASE}" >~/.tinyauth
msg_ok "Installed Tinyauth"

read -r -p "${TAB3}Enter your Tinyauth subdomain (e.g. https://tinyauth.example.com): " app_url

cat <<EOF >/opt/tinyauth/.env
DATABASE_PATH=/opt/tinyauth/database.db
USERS='${USER}'
APP_URL=${app_url}
EOF

msg_info "Creating Service"
cat <<'EOF' >/etc/init.d/tinyauth
#!/sbin/openrc-run
description="Tinyauth Service"

set -a
ENV_FILE="/opt/tinyauth/.env"
[ -f "$ENV_FILE" ] && . "$ENV_FILE"
set +a

command="/opt/tinyauth/tinyauth"
directory="/opt/tinyauth"
command_user="root"
command_background="true"
pidfile="/var/run/tinyauth.pid"

depend() {
    use net
}
EOF
chmod +x /etc/init.d/tinyauth
$STD rc-update add tinyauth default
msg_ok "Enabled Tinyauth Service"

msg_info "Starting Tinyauth"
$STD service tinyauth start
msg_ok "Started Tinyauth"

motd_ssh
customize
