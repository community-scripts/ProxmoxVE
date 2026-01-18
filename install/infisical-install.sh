#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://infisical.com/

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
  redis
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="infisical_db" PG_DB_USER="infisical" setup_postgresql_db
import_local_ip

msg_info "Setting up Infisical Repository"
setup_deb822_repo \
  "infisical" \
  "https://artifacts-infisical-core.infisical.com/infisical.gpg" \
  "https://artifacts-infisical-core.infisical.com/deb" \
  "stable"
msg_ok "Setup Infisical repository"

msg_info "Setting up Infisical"
AUTH_SECRET="$(openssl rand -base64 32 | tr -d '\n')"
ENC_KEY="$(openssl rand -hex 16 | tr -d '\n')"
$STD apt install -y infisical-core
mkdir -p /etc/infisical
cat <<EOF >/etc/infisical/infisical.rb
infisical_core['ENCRYPTION_KEY'] = '$ENC_KEY'
infisical_core['AUTH_SECRET'] = '$AUTH_SECRET'
infisical_core['HOST'] = '$LOCAL_IP'
infisical_core['DB_CONNECTION_URI'] = 'postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}'
infisical_core['REDIS_URL'] = 'redis://localhost:6379'
EOF
$STD infisical-ctl reconfigure
msg_ok "Setup Infisical"

motd_ssh
customize
cleanup_lxc
