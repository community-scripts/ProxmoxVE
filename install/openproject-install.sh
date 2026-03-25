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
$STD apt install -y \
  apt-transport-https \
  build-essential \
  autoconf
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="openproject" PG_DB_USER="openproject" setup_postgresql_db
API_KEY=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
echo "OpenProject API Key: $API_KEY" >>~/openproject.creds
fetch_and_deploy_gh_release "jemalloc" "jemalloc/jemalloc" "tarball"

msg_info "Compiling jemalloc (Patience)"
cd /opt/jemalloc
$STD ./autogen.sh
$STD make
$STD make install
msg_ok "Compiled jemalloc"

setup_deb822_repo \
  "openproject" \
  "https://packages.openproject.com/srv/deb/opf/openproject/gpg-key.gpg" \
  "https://packages.openproject.com/srv/deb/opf/openproject/stable/17/debian/" \
  "12"

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
systemctl stop openproject-web-1
if ! grep -qF 'Environment=LD_PRELOAD=/usr/local/lib/libjemalloc.so.2' /etc/systemd/system/openproject-web-1.service; then
  sed -i '/^\[Service\]/a Environment=LD_PRELOAD=/usr/local/lib/libjemalloc.so.2' /etc/systemd/system/openproject-web-1.service
fi
systemctl start openproject-web-1
msg_ok "Configured OpenProject"

motd_ssh
customize
cleanup_lxc
