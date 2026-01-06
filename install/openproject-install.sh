#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/opf/openproject

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y apt-transport-https
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="openproject" PG_DB_USER="openproject" setup_postgresql_db
API_KEY=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
echo "OpenProject API Key: $API_KEY" >>~/openproject.creds
import_local_ip

msg_info "Setting up OpenProject Repository"
curl -fsSL "https://dl.packager.io/srv/opf/openproject/key" | gpg --dearmor >/etc/apt/trusted.gpg.d/packager-io.gpg
curl -fsSL "https://dl.packager.io/srv/opf/openproject/stable/15/installer/debian/12.repo" -o "/etc/apt/sources.list.d/openproject.list"
$STD apt update
msg_ok "Setup OpenProject Repository"

msg_info "Installing OpenProject"
$STD apt install -y openproject
msg_ok "Installed OpenProject"

msg_info "Configuring OpenProject"
cat <<EOF >/etc/openproject/installer.dat
openproject/edition default

postgres/retry retry
postgres/autoinstall reuse
postgres/db_host 127.0.0.1
postgres/db_port 5432
postgres/db_username ${PG_DB_USER}
postgres/db_password ${PG_DB_PASS}
postgres/db_name ${PG_DB_NAME}
server/autoinstall install
server/variant apache2

server/hostname ${LOCAL_IP}
server/server_path_prefix /openproject
server/ssl no
server/variant apache2
repositories/api-key ${API_KEY}
repositories/svn-install skip
repositories/git-install install
repositories/git-path /var/db/openproject/git
repositories/git-http-backend /usr/lib/git-core/git-http-backend/
memcached/autoinstall install
openproject/admin_email admin@example.net
openproject/default_language en
EOF
$STD sudo openproject configure
msg_ok "Configured OpenProject"

motd_ssh
customize
cleanup_lxc
