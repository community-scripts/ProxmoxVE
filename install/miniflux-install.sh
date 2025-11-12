#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: omernaveedxyz
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://miniflux.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION=17 setup_postgresql
PG_DB_NAME="miniflux_db" PG_DB_USER="miniflux" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db
fetch_and_deploy_gh_release "miniflux" "miniflux/v2" "binary" "latest"

msg_info "Configuring Miniflux"
ADMIN_NAME=admin
ADMIN_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)"
cat <<EOF >/etc/miniflux.conf
# See https://miniflux.app/docs/configuration.html
DATABASE_URL=user=$PG_DB_USER password=$PG_DB_PASS dbname=$PG_DB_NAME sslmode=disable
CREATE_ADMIN=1
ADMIN_USERNAME=$ADMIN_NAME
ADMIN_PASSWORD=$ADMIN_PASS
LISTEN_ADDR=0.0.0.0:8080
EOF
{
  echo "ADMIN_USERNAME: $ADMIN_NAME"
  echo "ADMIN_PASSWORD: $ADMIN_PASS"
} >>~/miniflux.creds
$STD miniflux -migrate -config-file /etc/miniflux.conf
systemctl enable -q --now miniflux
msg_ok "Configured Miniflux"

motd_ssh
customize
cleanup_lxc
