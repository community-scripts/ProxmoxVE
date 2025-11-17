#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.passbolt.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y \
  apt-transport-https \
  python3-certbot-nginx \
  debconf-utils
msg_ok "Installed dependencies"

setup_mariadb
MARIADB_DB_NAME="passboltdb" MARIADB_DB_USER="passbolt" MARIADB_DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)" setup_mariadb_db
setup_deb822_repo \
  "passbolt" \
  "https://keys.openpgp.org/pks/lookup?op=get&options=mr&search=0x3D1A0346C8E1802F774AEF21DE8B853FC155581D" \
  "https://download.passbolt.com/ce/debian" \
  "buster" \
  "stable"
create_self_signed_cert "passbolt"

msg_info "Setting up Passbolt (Patience)"
export DEBIAN_FRONTEND=noninteractive
IP_ADDR=$(hostname -I | awk '{print $1}')
echo passbolt-ce-server passbolt/mysql-configuration boolean true | debconf-set-selections
echo passbolt-ce-server passbolt/mysql-passbolt-username string $MARIADB_DB_USER | debconf-set-selections
echo passbolt-ce-server passbolt/mysql-passbolt-password password $MARIADB_DB_PASS | debconf-set-selections
echo passbolt-ce-server passbolt/mysql-passbolt-password-repeat password $MARIADB_DB_PASS | debconf-set-selections
echo passbolt-ce-server passbolt/mysql-passbolt-dbname string $MARIADB_DB_NAME | debconf-set-selections
echo passbolt-ce-server passbolt/nginx-configuration boolean true | debconf-set-selections
echo passbolt-ce-server passbolt/nginx-configuration-three-choices select manual | debconf-set-selections
echo passbolt-ce-server passbolt/nginx-domain string $IP_ADDR | debconf-set-selections
echo passbolt-ce-server passbolt/nginx-certificate-file string /etc/ssl/passbolt/passbolt.crt | debconf-set-selections
echo passbolt-ce-server passbolt/nginx-certificate-key-file string /etc/ssl/passbolt/passbolt.key | debconf-set-selections
$STD apt install -y --no-install-recommends passbolt-ce-server
msg_ok "Setup Passbolt"

motd_ssh
customize
cleanup_lxc
